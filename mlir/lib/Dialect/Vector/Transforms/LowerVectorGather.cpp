//===- LowerVectorGather.cpp - Lower 'vector.gather' operation ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements target-independent rewrites and utilities to lower the
// 'vector.gather' operation.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Arith/Utils/Utils.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Utils/IndexingUtils.h"
#include "mlir/Dialect/Utils/StructuredOpsUtils.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/Dialect/Vector/Transforms/LoweringPatterns.h"
#include "mlir/Dialect/Vector/Utils/VectorUtils.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeUtilities.h"

#define DEBUG_TYPE "vector-gather-lowering"

using namespace mlir;
using namespace mlir::vector;

namespace {
/// Unrolls 2 or more dimensional `vector.gather` ops by unrolling the
/// outermost dimension. For example:
/// ```
/// %g = vector.gather %base[%c0][%v], %mask, %pass_thru :
///        ... into vector<2x3xf32>
///
/// ==>
///
/// %0   = arith.constant dense<0.0> : vector<2x3xf32>
/// %g0  = vector.gather %base[%c0][%v0], %mask0, %pass_thru0 : ...
/// %1   = vector.insert %g0, %0 [0] : vector<3xf32> into vector<2x3xf32>
/// %g1  = vector.gather %base[%c0][%v1], %mask1, %pass_thru1 : ...
/// %g   = vector.insert %g1, %1 [1] : vector<3xf32> into vector<2x3xf32>
/// ```
///
/// When applied exhaustively, this will produce a sequence of 1-d gather ops.
///
/// Supports vector types with a fixed leading dimension.
struct UnrollGather : OpRewritePattern<vector::GatherOp> {
  using Base::Base;

  LogicalResult matchAndRewrite(vector::GatherOp op,
                                PatternRewriter &rewriter) const override {
    Value indexVec = op.getIndices();
    Value maskVec = op.getMask();
    Value passThruVec = op.getPassThru();

    auto unrollGatherFn = [&](PatternRewriter &rewriter, Location loc,
                              VectorType subTy, int64_t index) {
      int64_t thisIdx[1] = {index};

      Value indexSubVec =
          vector::ExtractOp::create(rewriter, loc, indexVec, thisIdx);
      Value maskSubVec =
          vector::ExtractOp::create(rewriter, loc, maskVec, thisIdx);
      Value passThruSubVec =
          vector::ExtractOp::create(rewriter, loc, passThruVec, thisIdx);
      return vector::GatherOp::create(rewriter, loc, subTy, op.getBase(),
                                      op.getOffsets(), indexSubVec, maskSubVec,
                                      passThruSubVec, op.getAlignmentAttr());
    };

    return unrollVectorOp(op, rewriter, unrollGatherFn);
  }
};

/// Rewrites a vector.gather of a strided MemRef (from a memref.subview) as a
/// gather of the non-strided parent MemRef collapsed to 1-D, with indices
/// de-linearized from the subview's contiguous layout and re-linearized using
/// the parent's contiguous strides.
///
/// Example (rank-reducing, rank-2 source to 1-D):
/// ```mlir
///   %subview = memref.subview %M[5, 0] [100, 1] [1, 1]
///     : memref<105x3xf32> to memref<100xf32, strided<[3], offset: 15>>
///   %gather = vector.gather %subview[%c0] [%idxs], ...
/// ```
/// ==>
/// ```mlir
///   %collapsed = memref.collapse_shape %M [[0, 1]]
///     : memref<105x3xf32> into memref<315xf32>
///   %scaled = arith.muli %idxs, %c3 : vector<4xindex>
///   %new_idxs = arith.addi %scaled, %c15 : vector<4xindex>
///   %gather = vector.gather %collapsed[%c0] [%new_idxs], ...
/// ```
///
/// Example (same-rank, 3-D to 3-D with strided outer dim):
/// ```mlir
///   %subview = memref.subview %M[0, 0, 0] [2, 3, 4] [1, 1, 1]
///     : memref<2x5x4xf32> to memref<2x3x4xf32, strided<[20, 4, 1]>>
///   %gather = vector.gather %subview[%c0, %c0, %c0] [%idxs], ...
/// ```
/// ==>
/// ```mlir
///   %collapsed = memref.collapse_shape %M [[0, 1, 2]]
///     : memref<2x5x4xf32> into memref<40xf32>
///   // De-linearize with contiguous strides [12, 4, 1], re-linearize with
///   // parent strides [20, 4, 1]:
///   %d0 = arith.divui %idxs, %c12
///   %d1_tmp = arith.divui %idxs, %c4
///   %d1 = arith.remui %d1_tmp, %c3
///   %d2 = arith.remui %idxs, %c4
///   %new_idxs = %d0 * 20 + %d1 * 4 + %d2
///   %gather = vector.gather %collapsed[%c0] [%new_idxs], ...
/// ```
///
/// Handles any source rank, any result rank, and any stride values. Requires
/// the source to be contiguous (row-major strides) with a static offset, and
/// all subview strides/sizes/offset to be static.
struct RemoveStrideFromGatherSource : OpRewritePattern<vector::GatherOp> {
  using Base::Base;

  LogicalResult matchAndRewrite(vector::GatherOp op,
                                PatternRewriter &rewriter) const override {
    Value base = op.getBase();

    // Only handle gathers sourced from a memref.subview.
    auto subview = base.getDefiningOp<memref::SubViewOp>();
    if (!subview)
      return failure();

    auto resultType = subview.getResult().getType();
    auto sourceType = subview.getSource().getType();
    int64_t resultRank = resultType.getRank();

    // Verify the source (parent) is contiguous: strides must match row-major
    // layout computed from the shape. The parent offset must be static but may
    // be non-zero (e.g., when the parent is itself a subview). Since svOffset
    // already includes the parent offset, we subtract it to avoid
    // double-counting (the collapsed memref carries the parent offset in its
    // layout).
    SmallVector<int64_t> parentStrides;
    int64_t parentOffset;
    if (failed(sourceType.getStridesAndOffset(parentStrides, parentOffset)))
      return failure();
    if (ShapedType::isDynamic(parentOffset))
      return failure();
    int64_t expectedStride = 1;
    for (int64_t d = sourceType.getRank() - 1; d >= 0; --d) {
      if (ShapedType::isDynamic(sourceType.getShape()[d]) ||
          parentStrides[d] != expectedStride)
        return failure();
      expectedStride *= sourceType.getShape()[d];
    }

    // Get the subview result's strides and element offset (must all be static).
    SmallVector<int64_t> svStrides;
    int64_t svOffset;
    if (failed(resultType.getStridesAndOffset(svStrides, svOffset)))
      return failure();
    if (ShapedType::isDynamic(svOffset))
      return failure();
    if (llvm::any_of(svStrides, ShapedType::isDynamic))
      return failure();

    // Compute contiguous (row-major) strides from the subview result shape.
    // computeStrides requires static inner dims (asserts non-negative); the
    // outermost dim may be dynamic since it's not used in the computation.
    ArrayRef<int64_t> svShape = resultType.getShape();
    if (llvm::any_of(svShape.drop_front(), ShapedType::isDynamic))
      return failure();
    SmallVector<int64_t> contiguousStrides = computeStrides(svShape);

    // Check if the subview strides match contiguous layout. If so, only the
    // offset matters; if offset is also 0, there's nothing to do.
    bool needsRelinearization = (svStrides != contiguousStrides);
    if (!needsRelinearization && svOffset == parentOffset)
      return failure();

    Location loc = op.getLoc();
    VectorType vType = op.getIndices().getType();

    // Helper: create a splat vector constant matching the index vector's
    // element type (which may be index, i32, or i64).
    auto makeVecCst = [&](int64_t val) -> Value {
      Type elemTy = vType.getElementType();
      Attribute attr =
          elemTy.isIndex()
              ? cast<Attribute>(rewriter.getIndexAttr(val))
              : cast<Attribute>(rewriter.getIntegerAttr(elemTy, val));
      return arith::ConstantOp::create(rewriter, loc, vType,
                                       DenseElementsAttr::get(vType, attr));
    };

    // 1. Collapse the parent memref to 1-D.
    SmallVector<ReassociationIndices> reassoc = {
        llvm::to_vector(llvm::seq<int64_t>(0, sourceType.getRank()))};
    Value collapsed = memref::CollapseShapeOp::create(
        rewriter, loc, subview.getSource(), reassoc);

    // 2. Linearize the gather's base offsets into the subview's address space.
    //    Static offsets are folded into svOffset. We subtract parentOffset
    //    because svOffset already includes it, and the collapsed memref carries
    //    parentOffset in its own layout — without subtraction it would be
    //    counted twice.
    int64_t staticBaseOffset = svOffset - parentOffset;
    Value dynamicBaseOffset;
    for (int64_t d = 0; d < resultRank; ++d) {
      Value gatherOffset = op.getOffsets()[d];
      if (std::optional<int64_t> cst = getConstantIntValue(gatherOffset)) {
        staticBaseOffset += *cst * svStrides[d];
      } else {
        // Scale by the actual stride and accumulate.
        Value strideCst =
            rewriter.createOrFold<arith::ConstantIndexOp>(loc, svStrides[d]);
        Value term =
            arith::MulIOp::create(rewriter, loc, gatherOffset, strideCst);
        dynamicBaseOffset =
            dynamicBaseOffset
                ? arith::AddIOp::create(rewriter, loc, dynamicBaseOffset, term)
                : term;
      }
    }

    // 3. De-linearize the gather index vector using contiguous strides (from
    //    the subview result shape) and re-linearize with the subview's actual
    //    strides (which map dimension indices to flat offsets in the underlying
    //    buffer). We use vectorized arith ops rather than scalar
    //    affine.delinearize_index/linearize_index to keep the gather as a
    //    vector operation and avoid per-element scalarization.
    Value newIdxs;
    Value indexVec = op.getIndices();
    if (needsRelinearization) {
      for (int64_t d = 0; d < resultRank; ++d) {
        // De-linearize: dimIdx = (flatIdx / contiguousStride[d]) % shape[d].
        // The outermost dim (d==0) skips the modulo (already bounded).
        // The innermost dim skips the division when contiguousStride == 1.
        Value dimIdx = indexVec;
        if (contiguousStrides[d] != 1) {
          dimIdx = arith::DivUIOp::create(rewriter, loc, dimIdx,
                                          makeVecCst(contiguousStrides[d]));
        }
        if (d != 0) {
          dimIdx = arith::RemUIOp::create(rewriter, loc, dimIdx,
                                          makeVecCst(svShape[d]));
        }

        // Re-linearize: term = dimIdx * actualStride[d].
        Value term = dimIdx;
        if (svStrides[d] != 1) {
          term = arith::MulIOp::create(rewriter, loc, dimIdx,
                                       makeVecCst(svStrides[d]));
        }

        newIdxs = newIdxs ? arith::AddIOp::create(rewriter, loc, newIdxs, term)
                          : term;
      }
    } else {
      // Strides match contiguous layout — indices are already correct.
      newIdxs = indexVec;
    }

    // 4. Add dynamic base offset (broadcast scalar to vector).
    if (dynamicBaseOffset) {
      Type elemTy = vType.getElementType();
      if (!elemTy.isIndex()) {
        dynamicBaseOffset = arith::IndexCastOp::create(rewriter, loc, elemTy,
                                                       dynamicBaseOffset);
      }
      Value bcast = rewriter.createOrFold<vector::BroadcastOp>(
          loc, vType, dynamicBaseOffset);
      newIdxs = arith::AddIOp::create(rewriter, loc, newIdxs, bcast);
    }

    // 5. Add static element offset.
    if (staticBaseOffset != 0) {
      newIdxs = arith::AddIOp::create(rewriter, loc, newIdxs,
                                      makeVecCst(staticBaseOffset));
    }

    // 6. Create the new gather on the collapsed parent with a zero base offset.
    Value c0 = rewriter.createOrFold<arith::ConstantIndexOp>(loc, 0);
    Value newGather = vector::GatherOp::create(
        rewriter, loc, op.getResult().getType(), collapsed, ValueRange{c0},
        newIdxs, op.getMask(), op.getPassThru(), op.getAlignmentAttr());
    rewriter.replaceOp(op, newGather);

    return success();
  }
};

/// Turns 1-d `vector.gather` into a scalarized sequence of `vector.loads` or
/// `tensor.extract`s. To avoid out-of-bounds memory accesses, these
/// loads/extracts are made conditional using `scf.if` ops.
///
/// For multi-dimensional memrefs (rank > 1), the gather index is combined
/// with the offsets via linearize-then-delinearize to produce correct
/// N-D load indices:
///   idx = indices[i]
///   flatIdx = linearize(offsets, memrefShape) + idx
///   loadIndices = delinearize(flatIdx, memrefShape)
struct Gather1DToConditionalLoads : OpRewritePattern<vector::GatherOp> {
  using Base::Base;

  LogicalResult matchAndRewrite(vector::GatherOp op,
                                PatternRewriter &rewriter) const override {
    VectorType resultTy = op.getType();
    if (resultTy.getRank() != 1)
      return rewriter.notifyMatchFailure(op, "unsupported rank");

    if (resultTy.isScalable())
      return rewriter.notifyMatchFailure(op, "not a fixed-width vector");

    Location loc = op.getLoc();
    Type elemTy = resultTy.getElementType();
    // Vector type with a single element. Used to generate `vector.loads`.
    VectorType elemVecTy = VectorType::get({1}, elemTy);

    Value condMask = op.getMask();
    Value base = op.getBase();

    // For multi-dimensional memrefs, use linearize+delinearize to compute
    // correct N-D load indices from the 1-D gather index.
    // Note: no stride check is needed here because each element is loaded
    // individually as vector<1xelemTy>. Single-element vector.load is valid
    // on any memref regardless of stride (the stride only affects multi-element
    // contiguous loads).
    bool useDelinearization = false;
    if (auto memType = dyn_cast<MemRefType>(base.getType())) {
      if (memType.getRank() > 1)
        useDelinearization = true;
    }

    Value indexVec = rewriter.createOrFold<arith::IndexCastOp>(
        loc, op.getIndexVectorType().clone(rewriter.getIndexType()),
        op.getIndices());
    auto loadOffsets = llvm::to_vector(op.getOffsets());
    Value lastLoadOffset = loadOffsets.back();

    // Compute the memref shape and linearized offsets once, outside the
    // per-element loop.
    SmallVector<OpFoldResult> baseShape;
    Value linearizedOffsets;
    if (useDelinearization) {
      baseShape = memref::getMixedSizes(rewriter, loc, base);
      linearizedOffsets = affine::AffineLinearizeIndexOp::create(
          rewriter, loc, loadOffsets, baseShape, /*disjoint=*/false);
    }

    Value result = op.getPassThru();
    BoolAttr nontemporalAttr = nullptr;
    IntegerAttr alignmentAttr = op.getAlignmentAttr();

    // Emit a conditional access for each vector element.
    for (int64_t i = 0, e = resultTy.getNumElements(); i < e; ++i) {
      int64_t thisIdx[1] = {i};
      Value condition =
          vector::ExtractOp::create(rewriter, loc, condMask, thisIdx);
      Value index = vector::ExtractOp::create(rewriter, loc, indexVec, thisIdx);

      if (useDelinearization) {
        // The gather index offsets the innermost dimension. Combine with
        // the offsets by linearizing, adding the gather index, then
        // delinearizing back to N-D indices:
        //   flatIdx = linearize(offsets, shape) + idx
        //   loadIndices = delinearize(flatIdx, shape)
        Value flatIdx =
            rewriter.createOrFold<arith::AddIOp>(loc, linearizedOffsets, index);
        auto delinOp = affine::AffineDelinearizeIndexOp::create(
            rewriter, loc, flatIdx, baseShape, /*hasOuterBound=*/true);
        for (int64_t d = 0, rank = loadOffsets.size(); d < rank; ++d)
          loadOffsets[d] = delinOp.getResult(d);
      } else {
        loadOffsets.back() =
            rewriter.createOrFold<arith::AddIOp>(loc, lastLoadOffset, index);
      }

      auto loadBuilder = [&](OpBuilder &b, Location loc) {
        Value extracted;
        if (isa<MemRefType>(base.getType())) {
          // `vector.load` does not support scalar result; emit a vector load
          // and extract the single result instead.
          Value load =
              vector::LoadOp::create(b, loc, elemVecTy, base, loadOffsets,
                                     nontemporalAttr, alignmentAttr);
          int64_t zeroIdx[1] = {0};
          extracted = vector::ExtractOp::create(b, loc, load, zeroIdx);
        } else {
          extracted = tensor::ExtractOp::create(b, loc, base, loadOffsets);
        }

        Value newResult =
            vector::InsertOp::create(b, loc, extracted, result, thisIdx);
        scf::YieldOp::create(b, loc, newResult);
      };
      auto passThruBuilder = [result](OpBuilder &b, Location loc) {
        scf::YieldOp::create(b, loc, result);
      };

      result = scf::IfOp::create(rewriter, loc, condition,
                                 /*thenBuilder=*/loadBuilder,
                                 /*elseBuilder=*/passThruBuilder)
                   .getResult(0);
    }

    rewriter.replaceOp(op, result);
    return success();
  }
};
} // namespace

void mlir::vector::populateVectorGatherLoweringPatterns(
    RewritePatternSet &patterns, PatternBenefit benefit) {
  patterns.add<UnrollGather>(patterns.getContext(), benefit);
}

void mlir::vector::populateVectorGatherToConditionalLoadPatterns(
    RewritePatternSet &patterns, PatternBenefit benefit) {
  patterns.add<RemoveStrideFromGatherSource, Gather1DToConditionalLoads>(
      patterns.getContext(), benefit);
}
