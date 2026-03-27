// RUN: mlir-opt %s --test-vector-gather-lowering | FileCheck %s
// RUN: mlir-opt %s --test-vector-gather-lowering --canonicalize | FileCheck %s --check-prefix=CANON

// CHECK-LABEL: @gather_memref_1d
// CHECK-SAME:    ([[BASE:%.+]]: memref<?xf32>, [[IDXVEC:%.+]]: vector<2xindex>, [[MASK:%.+]]: vector<2xi1>, [[PASS:%.+]]: vector<2xf32>)
// CHECK-DAG:     [[M0:%.+]]    = vector.extract [[MASK]][0] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX0:.+]]  = vector.extract [[IDXVEC]][0] : index from vector<2xindex>
// CHECK-NEXT:    [[RES0:%.+]]  = scf.if [[M0]] -> (vector<2xf32>)
// CHECK-NEXT:      [[LD0:%.+]]   = vector.load [[BASE]][%[[IDX0]]] : memref<?xf32>, vector<1xf32>
// CHECK-NEXT:      [[ELEM0:%.+]] = vector.extract [[LD0]][0] : f32 from vector<1xf32>
// CHECK-NEXT:      [[INS0:%.+]]  = vector.insert [[ELEM0]], [[PASS]] [0] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS0]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[PASS]] : vector<2xf32>
// CHECK-DAG:     [[M1:%.+]]    = vector.extract [[MASK]][1] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX1:.+]]  = vector.extract [[IDXVEC]][1] : index from vector<2xindex>
// CHECK-NEXT:    [[RES1:%.+]]  = scf.if [[M1]] -> (vector<2xf32>)
// CHECK-NEXT:      [[LD1:%.+]]   = vector.load [[BASE]][%[[IDX1]]] : memref<?xf32>, vector<1xf32>
// CHECK-NEXT:      [[ELEM1:%.+]] = vector.extract [[LD1]][0] : f32 from vector<1xf32>
// CHECK-NEXT:      [[INS1:%.+]]  = vector.insert [[ELEM1]], [[RES0]] [1] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS1]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[RES0]] : vector<2xf32>
// CHECK:         return [[RES1]] : vector<2xf32>
func.func @gather_memref_1d(%base: memref<?xf32>, %v: vector<2xindex>, %mask: vector<2xi1>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : memref<?xf32>, vector<2xindex>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// CHECK-LABEL: @gather_memref_1d_i32_index
// CHECK-SAME:    ([[BASE:%.+]]: memref<?xf32>, [[IDXVEC:%.+]]: vector<2xi32>, [[MASK:%.+]]: vector<2xi1>, [[PASS:%.+]]: vector<2xf32>)
// CHECK-DAG:     [[C42:%.+]]   = arith.constant 42 : index
// CHECK-DAG:     [[IDXS:%.+]]  = arith.index_cast [[IDXVEC]] : vector<2xi32> to vector<2xindex>
// CHECK-DAG:     [[IDX0:%.+]]  = vector.extract [[IDXS]][0] : index from vector<2xindex>
// CHECK-NEXT:    %[[OFF0:.+]]  = arith.addi [[IDX0]], [[C42]] : index
// CHECK-NEXT:    [[RES0:%.+]]  = scf.if
// CHECK-NEXT:      [[LD0:%.+]]   = vector.load [[BASE]][%[[OFF0]]] : memref<?xf32>, vector<1xf32>
// CHECK:         else
// CHECK:         [[IDX1:%.+]]  = vector.extract [[IDXS]][1] : index from vector<2xindex>
// CHECK:         %[[OFF1:.+]]  = arith.addi [[IDX1]], [[C42]] : index
// CHECK:         [[RES1:%.+]]  = scf.if
// CHECK-NEXT:      [[LD1:%.+]]   = vector.load [[BASE]][%[[OFF1]]] : memref<?xf32>, vector<1xf32>
// CHECK:         else
// CHECK:         return [[RES1]] : vector<2xf32>
func.func @gather_memref_1d_i32_index(%base: memref<?xf32>, %v: vector<2xi32>, %mask: vector<2xi1>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 42 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : memref<?xf32>, vector<2xi32>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// CHECK-LABEL: @gather_memref_2d
// CHECK-SAME:    ([[BASE:%.+]]: memref<?x?xf32>, [[IDXVEC:%.+]]: vector<2x3xindex>, [[MASK:%.+]]: vector<2x3xi1>, [[PASS:%.+]]: vector<2x3xf32>)
// CHECK-DAG:     %[[C0:.+]]    = arith.constant 0 : index
// CHECK-DAG:     %[[C1:.+]]    = arith.constant 1 : index
// CHECK-DAG:     [[PTV0:%.+]]  = vector.extract [[PASS]][0] : vector<3xf32> from vector<2x3xf32>
// CHECK:         %[[LIN:.+]]   = affine.linearize_index [%[[C0]], %[[C1]]] by
// CHECK-DAG:     [[M0:%.+]]    = vector.extract [[MASK]][0, 0] : i1 from vector<2x3xi1>
// CHECK-DAG:     [[IDX0:%.+]]  = vector.extract [[IDXVEC]][0, 0] : index from vector<2x3xindex>
// CHECK:         %[[FLAT0:.+]] = arith.addi %[[LIN]], [[IDX0]] : index
// CHECK:         %[[DL0:.+]]:2 = affine.delinearize_index %[[FLAT0]] into
// CHECK:         [[RES0:%.+]]  = scf.if [[M0]] -> (vector<3xf32>)
// CHECK-NEXT:      [[LD0:%.+]]   = vector.load [[BASE]][%[[DL0]]#0, %[[DL0]]#1] : memref<?x?xf32>, vector<1xf32>
// CHECK-NEXT:      [[ELEM0:%.+]] = vector.extract [[LD0]][0] : f32 from vector<1xf32>
// CHECK-NEXT:      [[INS0:%.+]]  = vector.insert [[ELEM0]], [[PTV0]] [0] : f32 into vector<3xf32>
// CHECK-NEXT:      scf.yield [[INS0]] : vector<3xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[PTV0]] : vector<3xf32>
// CHECK-COUNT-5: scf.if
// CHECK:         [[FINAL:%.+]] = vector.insert %{{.+}}, %{{.+}} [1] : vector<3xf32> into vector<2x3xf32>
// CHECK-NEXT:    return [[FINAL]] : vector<2x3xf32>
 func.func @gather_memref_2d(%base: memref<?x?xf32>, %v: vector<2x3xindex>, %mask: vector<2x3xi1>, %pass_thru: vector<2x3xf32>) -> vector<2x3xf32> {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %0 = vector.gather %base[%c0, %c1][%v], %mask, %pass_thru : memref<?x?xf32>, vector<2x3xindex>, vector<2x3xi1>, vector<2x3xf32> into vector<2x3xf32>
  return %0 : vector<2x3xf32>
 }

// CHECK-LABEL: @scalable_gather_memref_2d
// CHECK-SAME:      %[[BASE:.*]]: memref<?x?xf32>,
// CHECK-SAME:      %[[IDXVEC:.*]]: vector<2x[3]xindex>,
// CHECK-SAME:      %[[MASK:.*]]: vector<2x[3]xi1>,
// CHECK-SAME:      %[[PASS:.*]]: vector<2x[3]xf32>
// CHECK:         %[[C0:.*]] = arith.constant 0 : index
// CHECK:         %[[C1:.*]] = arith.constant 1 : index
// CHECK:         %[[INIT:.*]] = ub.poison : vector<2x[3]xf32>
// CHECK:         %[[IDXVEC0:.*]] = vector.extract %[[IDXVEC]][0] : vector<[3]xindex> from vector<2x[3]xindex>
// CHECK:         %[[MASK0:.*]] = vector.extract %[[MASK]][0] : vector<[3]xi1> from vector<2x[3]xi1>
// CHECK:         %[[PASS0:.*]] = vector.extract %[[PASS]][0] : vector<[3]xf32> from vector<2x[3]xf32>
// CHECK:         %[[GATHER0:.*]] = vector.gather %[[BASE]]{{\[}}%[[C0]], %[[C1]]] {{\[}}%[[IDXVEC0]]], %[[MASK0]], %[[PASS0]] : memref<?x?xf32>, vector<[3]xindex>, vector<[3]xi1>, vector<[3]xf32> into vector<[3]xf32>
// CHECK:         %[[INS0:.*]] = vector.insert %[[GATHER0]], %[[INIT]] [0] : vector<[3]xf32> into vector<2x[3]xf32>
// CHECK:         %[[IDXVEC1:.*]] = vector.extract %[[IDXVEC]][1] : vector<[3]xindex> from vector<2x[3]xindex>
// CHECK:         %[[MASK1:.*]] = vector.extract %[[MASK]][1] : vector<[3]xi1> from vector<2x[3]xi1>
// CHECK:         %[[PASS1:.*]] = vector.extract %[[PASS]][1] : vector<[3]xf32> from vector<2x[3]xf32>
// CHECK:         %[[GATHER1:.*]] = vector.gather %[[BASE]]{{\[}}%[[C0]], %[[C1]]] {{\[}}%[[IDXVEC1]]], %[[MASK1]], %[[PASS1]] : memref<?x?xf32>, vector<[3]xindex>, vector<[3]xi1>, vector<[3]xf32> into vector<[3]xf32>
// CHECK:         %[[INS1:.*]] = vector.insert %[[GATHER1]], %[[INS0]] [1] : vector<[3]xf32> into vector<2x[3]xf32>
// CHECK-NEXT:    return %[[INS1]] : vector<2x[3]xf32>
func.func @scalable_gather_memref_2d(%base: memref<?x?xf32>, %v: vector<2x[3]xindex>, %mask: vector<2x[3]xi1>, %pass_thru: vector<2x[3]xf32>) -> vector<2x[3]xf32> {
 %c0 = arith.constant 0 : index
 %c1 = arith.constant 1 : index
 %0 = vector.gather %base[%c0, %c1][%v], %mask, %pass_thru : memref<?x?xf32>, vector<2x[3]xindex>, vector<2x[3]xi1>, vector<2x[3]xf32> into vector<2x[3]xf32>
 return %0 : vector<2x[3]xf32>
}

// CHECK-LABEL: @scalable_gather_memref_2d_with_alignment
// CHECK:         vector.gather
// CHECK-SAME:    {alignment = 8 : i64}
// CHECK:         vector.gather
// CHECK-SAME:    {alignment = 8 : i64}
func.func @scalable_gather_memref_2d_with_alignment(%base: memref<?x?xf32>, %v: vector<2x[3]xindex>, %mask: vector<2x[3]xi1>, %pass_thru: vector<2x[3]xf32>) -> vector<2x[3]xf32> {
 %c0 = arith.constant 0 : index
 %c1 = arith.constant 1 : index
 %0 = vector.gather %base[%c0, %c1][%v], %mask, %pass_thru {alignment = 8} : memref<?x?xf32>, vector<2x[3]xindex>, vector<2x[3]xi1>, vector<2x[3]xf32> into vector<2x[3]xf32>
 return %0 : vector<2x[3]xf32>
}

// CHECK-LABEL: @scalable_gather_cant_unroll
// CHECK-NOT: extract
// CHECK: vector.gather
// CHECK-NOT: extract
func.func @scalable_gather_cant_unroll(%base: memref<?x?xf32>, %v: vector<[4]x8xindex>, %mask: vector<[4]x8xi1>, %pass_thru: vector<[4]x8xf32>) -> vector<[4]x8xf32> {
 %c0 = arith.constant 0 : index
 %c1 = arith.constant 1 : index
 %0 = vector.gather %base[%c0, %c1][%v], %mask, %pass_thru : memref<?x?xf32>, vector<[4]x8xindex>, vector<[4]x8xi1>, vector<[4]x8xf32> into vector<[4]x8xf32>
 return %0 : vector<[4]x8xf32>
}

// CHECK-LABEL: @gather_tensor_1d
// CHECK-SAME:    ([[BASE:%.+]]: tensor<?xf32>, [[IDXVEC:%.+]]: vector<2xindex>, [[MASK:%.+]]: vector<2xi1>, [[PASS:%.+]]: vector<2xf32>)
// CHECK-DAG:     [[M0:%.+]]    = vector.extract [[MASK]][0] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX0:.+]]  = vector.extract [[IDXVEC]][0] : index from vector<2xindex>
// CHECK-NEXT:    [[RES0:%.+]]  = scf.if [[M0]] -> (vector<2xf32>)
// CHECK-NEXT:      [[ELEM0:%.+]] = tensor.extract [[BASE]][%[[IDX0]]] : tensor<?xf32>
// CHECK-NEXT:      [[INS0:%.+]]  = vector.insert [[ELEM0]], [[PASS]] [0] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS0]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[PASS]] : vector<2xf32>
// CHECK-DAG:     [[M1:%.+]]    = vector.extract [[MASK]][1] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX1:.+]]  = vector.extract [[IDXVEC]][1] : index from vector<2xindex>
// CHECK-NEXT:    [[RES1:%.+]]  = scf.if [[M1]] -> (vector<2xf32>)
// CHECK-NEXT:      [[ELEM1:%.+]] = tensor.extract [[BASE]][%[[IDX1]]] : tensor<?xf32>
// CHECK-NEXT:      [[INS1:%.+]]  = vector.insert [[ELEM1]], [[RES0]] [1] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS1]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[RES0]] : vector<2xf32>
// CHECK:         return [[RES1]] : vector<2xf32>
func.func @gather_tensor_1d(%base: tensor<?xf32>, %v: vector<2xindex>, %mask: vector<2xi1>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : tensor<?xf32>, vector<2xindex>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// CHECK-LABEL: @gather_memref_non_unit_stride_read_1_element
// CHECK: %[[MASK:.*]] = vector.extract %arg2[0] : i1 from vector<1xi1>
// CHECK: %[[IDX:.*]] = vector.extract %arg1[0] : index from vector<1xindex>
// CHECK: %[[RET:.*]] = scf.if %[[MASK]] -> (vector<1xf32>) {
// CHECK:   %[[VEC:.*]] = vector.load %arg0[%[[IDX]]] : memref<4xf32, strided<[2]>>, vector<1xf32>
// CHECK:   %[[VAL:.*]] = vector.extract %[[VEC]][0] : f32 from vector<1xf32>
// CHECK:   %[[RES:.*]] = vector.insert %[[VAL]], %arg3 [0] : f32 into vector<1xf32>
// CHECK:   scf.yield %[[RES]] : vector<1xf32>
// CHECK: } else {
// CHECK:    scf.yield %arg3 : vector<1xf32>
// CHECK: }
// CHECK: return %[[RET]] : vector<1xf32>
func.func @gather_memref_non_unit_stride_read_1_element(%base: memref<4xf32, strided<[2]>>, %v: vector<1xindex>, %mask: vector<1xi1>, %pass_thru: vector<1xf32>) -> vector<1xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : memref<4xf32, strided<[2]>>, vector<1xindex>, vector<1xi1>, vector<1xf32> into vector<1xf32>
  return %0 : vector<1xf32>
}

// Verify that non-unit stride with multi-element gather is now lowered
// to conditional loads (each load is vector<1xf32>, which is always valid
// regardless of stride).

// CHECK-LABEL: @gather_memref_non_unit_stride_read_more_than_1_element
// CHECK-SAME:    ([[BASE:%.+]]: memref<4xf32, strided<[2]>>, [[IDXVEC:%.+]]: vector<2xindex>, [[MASK:%.+]]: vector<2xi1>, [[PASS:%.+]]: vector<2xf32>)
// CHECK-DAG:     [[M0:%.+]]    = vector.extract [[MASK]][0] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX0:.+]]  = vector.extract [[IDXVEC]][0] : index from vector<2xindex>
// CHECK-NEXT:    [[RES0:%.+]]  = scf.if [[M0]] -> (vector<2xf32>)
// CHECK-NEXT:      [[LD0:%.+]]   = vector.load [[BASE]][%[[IDX0]]] : memref<4xf32, strided<[2]>>, vector<1xf32>
// CHECK-NEXT:      [[ELEM0:%.+]] = vector.extract [[LD0]][0] : f32 from vector<1xf32>
// CHECK-NEXT:      [[INS0:%.+]]  = vector.insert [[ELEM0]], [[PASS]] [0] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS0]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[PASS]] : vector<2xf32>
// CHECK-DAG:     [[M1:%.+]]    = vector.extract [[MASK]][1] : i1 from vector<2xi1>
// CHECK-DAG:     %[[IDX1:.+]]  = vector.extract [[IDXVEC]][1] : index from vector<2xindex>
// CHECK-NEXT:    [[RES1:%.+]]  = scf.if [[M1]] -> (vector<2xf32>)
// CHECK-NEXT:      [[LD1:%.+]]   = vector.load [[BASE]][%[[IDX1]]] : memref<4xf32, strided<[2]>>, vector<1xf32>
// CHECK-NEXT:      [[ELEM1:%.+]] = vector.extract [[LD1]][0] : f32 from vector<1xf32>
// CHECK-NEXT:      [[INS1:%.+]]  = vector.insert [[ELEM1]], [[RES0]] [1] : f32 into vector<2xf32>
// CHECK-NEXT:      scf.yield [[INS1]] : vector<2xf32>
// CHECK-NEXT:    else
// CHECK-NEXT:      scf.yield [[RES0]] : vector<2xf32>
// CHECK:         return [[RES1]] : vector<2xf32>
func.func @gather_memref_non_unit_stride_read_more_than_1_element(%base: memref<4xf32, strided<[2]>>, %v: vector<2xindex>, %mask: vector<2xi1>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : memref<4xf32, strided<[2]>>, vector<2xindex>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// CHECK-LABEL: @gather_tensor_2d
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:  scf.if
// CHECK:    tensor.extract
// CHECK:  else
// CHECK:       [[FINAL:%.+]] = vector.insert %{{.+}}, %{{.+}} [1] : vector<3xf32> into vector<2x3xf32>
// CHECK-NEXT:  return [[FINAL]] : vector<2x3xf32>
 func.func @gather_tensor_2d(%base: tensor<?x?xf32>, %v: vector<2x3xindex>, %mask: vector<2x3xi1>, %pass_thru: vector<2x3xf32>) -> vector<2x3xf32> {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %0 = vector.gather %base[%c0, %c1][%v], %mask, %pass_thru : tensor<?x?xf32>, vector<2x3xindex>, vector<2x3xi1>, vector<2x3xf32> into vector<2x3xf32>
  return %0 : vector<2x3xf32>
 }

// Check that all-set and no-set maskes get optimized out after canonicalization.

// CANON-LABEL: @gather_tensor_1d_all_set
// CANON-NOT:     scf.if
// CANON:         tensor.extract
// CANON:         tensor.extract
// CANON:         [[FINAL:%.+]] = vector.from_elements %{{.+}}, %{{.+}} : vector<2xf32>
// CANON-NEXT:    return [[FINAL]] : vector<2xf32>
func.func @gather_tensor_1d_all_set(%base: tensor<?xf32>, %v: vector<2xindex>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %mask = arith.constant dense <true> : vector<2xi1>
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : tensor<?xf32>, vector<2xindex>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// CANON-LABEL: @gather_tensor_1d_none_set
// CANON-SAME:    ([[BASE:%.+]]: tensor<?xf32>, [[IDXVEC:%.+]]: vector<2xindex>, [[PASS:%.+]]: vector<2xf32>)
// CANON-NEXT:    return [[PASS]] : vector<2xf32>
func.func @gather_tensor_1d_none_set(%base: tensor<?xf32>, %v: vector<2xindex>, %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %mask = arith.constant dense <false> : vector<2xi1>
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : tensor<?xf32>, vector<2xindex>, vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// Check that vector.gather of a strided memref is replaced with a
// vector.gather with indices encoding the original strides. Note that multiple
// patterns are run for this example, e.g.:
  //  1. "remove stride from gather source"
  //  2. "flatten gather"
// However, the main goal is to the test Pattern 1 above.
#map = affine_map<()[s0] -> (s0 * 4096)>
func.func @strided_gather(%base : memref<100x3xf32>,
                          %idxs : vector<4xindex>,
                          %x : index, %y : index) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %x_1 = affine.apply #map()[%x]
  // Strided MemRef
  %subview = memref.subview %base[0, 0] [100, 1] [1, 1] : memref<100x3xf32> to memref<100xf32, strided<[3]>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.000000e+00> : vector<4xf32>
  // Gather of a strided MemRef
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru {alignment = 8} : memref<100xf32, strided<[3]>>, vector<4xindex>, vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}
// CHECK-LABEL:   func.func @strided_gather(
// CHECK-SAME:                         %[[base:.*]]: memref<100x3xf32>,
// CHECK-SAME:                         %[[IDXS:.*]]: vector<4xindex>,
// CHECK-SAME:                         %[[VAL_4:.*]]: index,
// CHECK-SAME:                         %[[VAL_5:.*]]: index) -> vector<4xf32> {
// CHECK:           %[[TRUE:.*]] = arith.constant true
// CHECK:           %[[CST_3:.*]] = arith.constant dense<3> : vector<4xindex>

// CHECK:           %[[COLLAPSED:.*]] = memref.collapse_shape %[[base]] {{\[\[}}0, 1]] : memref<100x3xf32> into memref<300xf32>
// CHECK:           %[[NEW_IDXS:.*]] = arith.muli %[[IDXS]], %[[CST_3]] : vector<4xindex>

// CHECK:           %[[IDX_0:.*]] = vector.extract %[[NEW_IDXS]][0] : index from vector<4xindex>
// CHECK:           scf.if %[[TRUE]] -> (vector<4xf32>)
// CHECK:             %[[M_0:.*]] = vector.load %[[COLLAPSED]][%[[IDX_0]]] {alignment = 8 : i64} : memref<300xf32>, vector<1xf32>
// CHECK:             %[[V_0:.*]] = vector.extract %[[M_0]][0] : f32 from vector<1xf32>

// CHECK:           %[[IDX_1:.*]] = vector.extract %[[NEW_IDXS]][1] : index from vector<4xindex>
// CHECK:           scf.if %[[TRUE]] -> (vector<4xf32>)
// CHECK:             %[[M_1:.*]] = vector.load %[[COLLAPSED]][%[[IDX_1]]] {alignment = 8 : i64} : memref<300xf32>, vector<1xf32>
// CHECK:             %[[V_1:.*]] = vector.extract %[[M_1]][0] : f32 from vector<1xf32>

// CHECK:           %[[IDX_2:.*]] = vector.extract %[[NEW_IDXS]][2] : index from vector<4xindex>
// CHECK:           scf.if %[[TRUE]] -> (vector<4xf32>)
// CHECK:             %[[M_2:.*]] = vector.load %[[COLLAPSED]][%[[IDX_2]]] {alignment = 8 : i64} : memref<300xf32>, vector<1xf32>
// CHECK:             %[[V_2:.*]] = vector.extract %[[M_2]][0] : f32 from vector<1xf32>

// CHECK:           %[[IDX_3:.*]] = vector.extract %[[NEW_IDXS]][3] : index from vector<4xindex>
// CHECK:           scf.if %[[TRUE]] -> (vector<4xf32>)
// CHECK:             %[[M_3:.*]] = vector.load %[[COLLAPSED]][%[[IDX_3]]] {alignment = 8 : i64} : memref<300xf32>, vector<1xf32>
// CHECK:             %[[V_3:.*]] = vector.extract %[[M_3]][0] : f32 from vector<1xf32>

// Rank-3 parent with rank-reducing subview to 1-D. The stride is 15 (= 5*3),
// the product of the two trailing dimensions.

// CHECK-LABEL: @strided_gather_rank3_parent
// CHECK-SAME:    (%[[BASE:.*]]: memref<10x5x3xf32>, %[[IDXS:.*]]: vector<4xindex>)
// CHECK:         %[[CST15:.*]] = arith.constant dense<15> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1, 2]] : memref<10x5x3xf32> into memref<150xf32>
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST15]] : vector<4xindex>
// CHECK:         vector.extract %[[SCALED]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_rank3_parent(%base : memref<10x5x3xf32>,
                                       %idxs : vector<4xindex>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[0, 0, 0] [10, 1, 1] [1, 1, 1]
      : memref<10x5x3xf32> to memref<10xf32, strided<[15]>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru
      : memref<10xf32, strided<[15]>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Combined non-zero subview offset AND non-zero static gather base offset.
// subview offset = 5*3 = 15, base_offset(10) * stride(3) = 30, total = 45.

// CHECK-LABEL: @strided_gather_combined_offsets
// CHECK-SAME:    (%[[BASE:.*]]: memref<105x3xf32>, %[[IDXS:.*]]: vector<4xindex>)
// CHECK-DAG:     %[[CST45:.*]] = arith.constant dense<45> : vector<4xindex>
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1]] : memref<105x3xf32> into memref<315xf32>
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST3]] : vector<4xindex>
// CHECK:         %[[OFFSET:.*]] = arith.addi %[[SCALED]], %[[CST45]] : vector<4xindex>
// CHECK:         vector.extract %[[OFFSET]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_combined_offsets(%base : memref<105x3xf32>,
                                           %idxs : vector<4xindex>) -> vector<4xf32> {
  %c10 = arith.constant 10 : index
  %subview = memref.subview %base[5, 0] [100, 1] [1, 1]
      : memref<105x3xf32> to memref<100xf32, strided<[3], offset: 15>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c10] [%idxs], %mask, %pass_thru
      : memref<100xf32, strided<[3], offset: 15>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// i32 index type with dynamic base offset. The index-typed base offset must
// be cast to i32 before broadcasting to match the index vector type.

// CHECK-LABEL: @strided_gather_i32_dynamic_base_offset
// CHECK-SAME:    (%[[BASE:.*]]: memref<100x3xf32>, %[[IDXS:.*]]: vector<4xi32>, %[[OFF:.*]]: index)
// CHECK-DAG:     %[[CST3_SCALAR:.*]] = arith.constant 3 : index
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xi32>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]]
// CHECK:         %[[SOFF:.*]] = arith.muli %[[OFF]], %[[CST3_SCALAR]] : index
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST3]] : vector<4xi32>
// CHECK:         %[[CAST:.*]] = arith.index_cast %[[SOFF]] : index to i32
// CHECK:         %[[BCAST:.*]] = vector.broadcast %[[CAST]] : i32 to vector<4xi32>
// CHECK:         %[[WITH_OFF:.*]] = arith.addi %[[SCALED]], %[[BCAST]] : vector<4xi32>
func.func @strided_gather_i32_dynamic_base_offset(
    %base : memref<100x3xf32>,
    %idxs : vector<4xi32>, %off : index) -> vector<4xf32> {
  %subview = memref.subview %base[0, 0] [100, 1] [1, 1]
      : memref<100x3xf32> to memref<100xf32, strided<[3]>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%off] [%idxs], %mask, %pass_thru
      : memref<100xf32, strided<[3]>>, vector<4xi32>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Step strides > 1 on the kept dimension. The subview has step=2,
// producing stride = source_stride * step = 3 * 2 = 6.
// The pattern correctly reads the stride from the subview result type.

// CHECK-LABEL: @strided_gather_step_strides
// CHECK-SAME:    (%[[BASE:.*]]: memref<20x3xf32>, %[[IDXS:.*]]: vector<4xindex>)
// CHECK-DAG:     %[[CST6:.*]] = arith.constant dense<6> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1]] : memref<20x3xf32> into memref<60xf32>
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST6]] : vector<4xindex>
// CHECK:         vector.extract %[[SCALED]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_step_strides(%base : memref<20x3xf32>,
                                       %idxs : vector<4xindex>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[0, 0] [10, 1] [2, 1]
      : memref<20x3xf32> to memref<10xf32, strided<[6]>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru
      : memref<10xf32, strided<[6]>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Stride-1 subview with non-zero offset. The strides are contiguous but
// the element offset is non-zero. RemoveStrideFromGatherSource collapses the
// parent to 1-D and adds the offset to the index vector.

// CHECK-LABEL: @strided_gather_stride1_with_offset
// CHECK-SAME:    (%[[BASE:.*]]: memref<20xf32>, %[[IDXS:.*]]: vector<4xindex>)
// CHECK:         %[[CST5:.*]] = arith.constant dense<5> : vector<4xindex>
// CHECK:         %[[OFFSET:.*]] = arith.addi %[[IDXS]], %[[CST5]] : vector<4xindex>
// CHECK:         vector.extract %[[OFFSET]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]]
func.func @strided_gather_stride1_with_offset(%base : memref<20xf32>,
                                              %idxs : vector<4xindex>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[5] [10] [1]
      : memref<20xf32> to memref<10xf32, strided<[1], offset: 5>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru
      : memref<10xf32, strided<[1], offset: 5>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Rank-reducing 3-D to 2-D: slicing the innermost dim (size 1) produces a
// 2-D subview with strides [15, 3]. Contiguous strides for shape [4, 5]
// are [5, 1]. De-linearize with [5, 1], re-linearize with [15, 3].

// CHECK-LABEL: @strided_gather_3d_to_2d
// CHECK-SAME:    (%[[BASE:.*]]: memref<4x5x3xf32>, %[[IDXS:.*]]: vector<4xindex>,
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xindex>
// CHECK-DAG:     %[[CST15:.*]] = arith.constant dense<15> : vector<4xindex>
// CHECK-DAG:     %[[CST5:.*]] = arith.constant dense<5> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1, 2]] : memref<4x5x3xf32> into memref<60xf32>
//  De-linearize dim 0: idx / 5, re-linearize with stride 15
// CHECK:         %[[D0:.*]] = arith.divui %[[IDXS]], %[[CST5]]
// CHECK:         %[[T0:.*]] = arith.muli %[[D0]], %[[CST15]]
//  De-linearize dim 1: idx % 5, re-linearize with stride 3
// CHECK:         %[[D1:.*]] = arith.remui %[[IDXS]], %[[CST5]]
// CHECK:         %[[T1:.*]] = arith.muli %[[D1]], %[[CST3]]
// CHECK:         %[[NEWIDX:.*]] = arith.addi %[[T0]], %[[T1]]
// CHECK:         vector.extract %[[NEWIDX]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_3d_to_2d(%base : memref<4x5x3xf32>,
                                    %idxs : vector<4xindex>,
                                    %mask : vector<4xi1>,
                                    %pt : vector<4xf32>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[0, 0, 0] [4, 5, 1] [1, 1, 1]
      : memref<4x5x3xf32> to memref<4x5xf32, strided<[15, 3]>>
  %r = vector.gather %subview[%c0, %c0] [%idxs], %mask, %pt
      : memref<4x5xf32, strided<[15, 3]>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %r : vector<4xf32>
}

// Non-rank-reducing: 3-D subview from 3-D parent with strided outer dim.
// Contiguous strides for shape [2, 3, 4] are [12, 4, 1]. Actual strides
// from parent (dim 1 is 5, not 3) are [20, 4, 1]. The pattern de-linearizes
// with [12, 4, 1] and re-linearizes with [20, 4, 1].

// CHECK-LABEL: @strided_gather_3d_to_3d
// CHECK-SAME:    (%[[BASE:.*]]: memref<2x5x4xf32>, %[[IDXS:.*]]: vector<4xindex>,
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xindex>
// CHECK-DAG:     %[[CST4:.*]] = arith.constant dense<4> : vector<4xindex>
// CHECK-DAG:     %[[CST20:.*]] = arith.constant dense<20> : vector<4xindex>
// CHECK-DAG:     %[[CST12:.*]] = arith.constant dense<12> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1, 2]] : memref<2x5x4xf32> into memref<40xf32>
//  De-linearize dim 0: idx / 12, re-linearize with stride 20
// CHECK:         %[[D0:.*]] = arith.divui %[[IDXS]], %[[CST12]]
// CHECK:         %[[T0:.*]] = arith.muli %[[D0]], %[[CST20]]
//  De-linearize dim 1: (idx / 4) % 3, re-linearize with stride 4
// CHECK:         %[[D1_DIV:.*]] = arith.divui %[[IDXS]], %[[CST4]]
// CHECK:         %[[D1:.*]] = arith.remui %[[D1_DIV]], %[[CST3]]
// CHECK:         %[[T1:.*]] = arith.muli %[[D1]], %[[CST4]]
// CHECK:         %[[SUM01:.*]] = arith.addi %[[T0]], %[[T1]]
//  De-linearize dim 2: idx % 4 (innermost, stride=1)
// CHECK:         %[[D2:.*]] = arith.remui %[[IDXS]], %[[CST4]]
// CHECK:         %[[NEWIDX:.*]] = arith.addi %[[SUM01]], %[[D2]]
// CHECK:         vector.extract %[[NEWIDX]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_3d_to_3d(%base : memref<2x5x4xf32>,
                                    %idxs : vector<4xindex>,
                                    %mask : vector<4xi1>,
                                    %pt : vector<4xf32>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[0, 0, 0] [2, 3, 4] [1, 1, 1]
      : memref<2x5x4xf32> to memref<2x3x4xf32, strided<[20, 4, 1]>>
  %r = vector.gather %subview[%c0, %c0, %c0] [%idxs], %mask, %pt
      : memref<2x3x4xf32, strided<[20, 4, 1]>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %r : vector<4xf32>
}

// Non-zero parent offset. The parent memref has offset 50 (e.g., itself from
// a prior subview). The subview's svOffset (65) already includes the parent's
// offset: 65 = 50 + 5*3. The pattern subtracts the parent offset to avoid
// double-counting with the collapsed memref's layout (which carries offset 50).
// So staticBaseOffset = 65 - 50 = 15.

// CHECK-LABEL: @strided_gather_nonzero_parent_offset
// CHECK-SAME:    (%[[BASE:.*]]: memref<100x3xf32, strided<[3, 1], offset: 50>>, %[[IDXS:.*]]: vector<4xindex>)
// CHECK-DAG:     %[[CST15:.*]] = arith.constant dense<15> : vector<4xindex>
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1]]
// CHECK-SAME:      memref<100x3xf32, strided<[3, 1], offset: 50>> into memref<300xf32, strided<[1], offset: 50>>
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST3]] : vector<4xindex>
// CHECK:         %[[OFFSET:.*]] = arith.addi %[[SCALED]], %[[CST15]] : vector<4xindex>
// CHECK:         vector.extract %[[OFFSET]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_nonzero_parent_offset(
    %base : memref<100x3xf32, strided<[3, 1], offset: 50>>,
    %idxs : vector<4xindex>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[5, 0] [95, 1] [1, 1]
      : memref<100x3xf32, strided<[3, 1], offset: 50>>
        to memref<95xf32, strided<[3], offset: 65>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru
      : memref<95xf32, strided<[3], offset: 65>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Combined dynamic gather base offset + non-zero subview offset.
// Subview offset = 5*3 = 15. Dynamic base offset is scaled by stride 3
// and broadcast-added to the index vector. Static offset 15 is added last.

// CHECK-LABEL: @strided_gather_dynamic_base_plus_subview_offset
// CHECK-SAME:    (%[[BASE:.*]]: memref<105x3xf32>, %[[IDXS:.*]]: vector<4xindex>, %[[OFF:.*]]: index)
// CHECK-DAG:     %[[CST15:.*]] = arith.constant dense<15> : vector<4xindex>
// CHECK-DAG:     %[[CST3_SCALAR:.*]] = arith.constant 3 : index
// CHECK-DAG:     %[[CST3:.*]] = arith.constant dense<3> : vector<4xindex>
// CHECK:         %[[COLLAPSED:.*]] = memref.collapse_shape %[[BASE]] {{\[\[}}0, 1]] : memref<105x3xf32> into memref<315xf32>
// CHECK:         %[[SOFF:.*]] = arith.muli %[[OFF]], %[[CST3_SCALAR]] : index
// CHECK:         %[[SCALED:.*]] = arith.muli %[[IDXS]], %[[CST3]] : vector<4xindex>
// CHECK:         %[[BCAST:.*]] = vector.broadcast %[[SOFF]] : index to vector<4xindex>
// CHECK:         %[[WITH_DYN:.*]] = arith.addi %[[SCALED]], %[[BCAST]] : vector<4xindex>
// CHECK:         %[[WITH_STATIC:.*]] = arith.addi %[[WITH_DYN]], %[[CST15]] : vector<4xindex>
// CHECK:         vector.extract %[[WITH_STATIC]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[COLLAPSED]]
func.func @strided_gather_dynamic_base_plus_subview_offset(
    %base : memref<105x3xf32>,
    %idxs : vector<4xindex>, %off : index) -> vector<4xf32> {
  %subview = memref.subview %base[5, 0] [100, 1] [1, 1]
      : memref<105x3xf32> to memref<100xf32, strided<[3], offset: 15>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%off] [%idxs], %mask, %pass_thru
      : memref<100xf32, strided<[3], offset: 15>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// Dynamic parent shape and dynamic subview offset: RemoveStrideFromGatherSource
// bails out (requires static strides/offset and contiguous parent).
// Gather1DToConditionalLoads handles it — loads directly on the subview memref.

// CHECK-LABEL: @strided_gather_dynamic_bailout
// CHECK-SAME:    (%[[BASE:.*]]: memref<?x3xf32>, %[[IDXS:.*]]: vector<4xindex>,
//   CHECK-NOT:   memref.collapse_shape
//   CHECK-NOT:   arith.muli {{.*}} dense
// CHECK:         %[[SV:.*]] = memref.subview %[[BASE]]
// CHECK:         vector.extract %[[IDXS]][0]
// CHECK:         scf.if
// CHECK:           vector.load %[[SV]]{{.*}} : memref<?xf32, strided<[3], offset: ?>>, vector<1xf32>
func.func @strided_gather_dynamic_bailout(
    %base : memref<?x3xf32>,
    %idxs : vector<4xindex>,
    %off : index, %sz : index) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %subview = memref.subview %base[%off, 0] [%sz, 1] [1, 1]
      : memref<?x3xf32> to memref<?xf32, strided<[3], offset: ?>>
  %mask = arith.constant dense<true> : vector<4xi1>
  %pass_thru = arith.constant dense<0.0> : vector<4xf32>
  %res = vector.gather %subview[%c0] [%idxs], %mask, %pass_thru
      : memref<?xf32, strided<[3], offset: ?>>, vector<4xindex>,
        vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %res : vector<4xf32>
}

// CHECK-LABEL: @scalable_gather_1d
// CHECK-NOT: extract
// CHECK: vector.gather
// CHECK-NOT: extract
func.func @scalable_gather_1d(%base: tensor<?xf32>, %v: vector<[2]xindex>, %mask: vector<[2]xi1>, %pass_thru: vector<[2]xf32>) -> vector<[2]xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0][%v], %mask, %pass_thru : tensor<?xf32>, vector<[2]xindex>, vector<[2]xi1>, vector<[2]xf32> into vector<[2]xf32>
  return %0 : vector<[2]xf32>
}

// Verify that gather on a 2D memref with non-unit innermost stride is lowered
// correctly. The delinearization uses the memref's shape (logical dimensions),
// and each single-element vector.load handles the strided addressing.
//   memref<4x3xf32, strided<[8, 2]>>: shape [4, 3], strides [8, 2]
//   Gather index 5 (contiguous strides [3, 1]) → delinearize → (1, 2)
//   vector.load at [1, 2] → address: base + 1*8 + 2*2 = base + 12

// With zero base offsets, the linearize folds to 0 and the addi folds away,
// leaving just the delinearize of the raw index.

// CHECK-LABEL: @gather_memref_2d_nonunit_inner_stride
// CHECK-SAME:    (%[[BASE:.+]]: memref<4x3xf32, strided<[8, 2]>>, %[[IDXVEC:.+]]: vector<2xindex>, %[[MASK:.+]]: vector<2xi1>, %[[PASS:.+]]: vector<2xf32>)
// CHECK:         %[[IDX0:.+]] = vector.extract %[[IDXVEC]][0]
// CHECK:         %[[DL0:.+]]:2 = affine.delinearize_index %[[IDX0]] into (4, 3)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%[[DL0]]#0, %[[DL0]]#1] : memref<4x3xf32, strided<[8, 2]>>, vector<1xf32>
// CHECK:         %[[IDX1:.+]] = vector.extract %[[IDXVEC]][1]
// CHECK:         affine.delinearize_index
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%{{.+}}, %{{.+}}] : memref<4x3xf32, strided<[8, 2]>>, vector<1xf32>
func.func @gather_memref_2d_nonunit_inner_stride(
    %base: memref<4x3xf32, strided<[8, 2]>>,
    %v: vector<2xindex>, %mask: vector<2xi1>,
    %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0, %c0][%v], %mask, %pass_thru
    : memref<4x3xf32, strided<[8, 2]>>, vector<2xindex>,
      vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// Verify that gather on a 3D strided memref (from a same-rank subview pattern)
// is lowered correctly. The strides [20, 4, 1] differ from contiguous [12, 4, 1]
// for shape [2, 3, 4], but delinearization + N-D load handles this.

// CHECK-LABEL: @gather_memref_3d_strided
// CHECK-SAME:    (%[[BASE:.+]]: memref<2x3x4xf32, strided<[20, 4, 1]>>,
// CHECK-SAME:     %[[IDXVEC:.+]]: vector<2xindex>,
// CHECK:         %[[IDX0:.+]] = vector.extract %[[IDXVEC]][0]
// CHECK:         %[[DL0:.+]]:3 = affine.delinearize_index %[[IDX0]] into (2, 3, 4)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%[[DL0]]#0, %[[DL0]]#1, %[[DL0]]#2] : memref<2x3x4xf32, strided<[20, 4, 1]>>, vector<1xf32>
func.func @gather_memref_3d_strided(
    %base: memref<2x3x4xf32, strided<[20, 4, 1]>>,
    %v: vector<2xindex>, %mask: vector<2xi1>,
    %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0, %c0, %c0][%v], %mask, %pass_thru
    : memref<2x3x4xf32, strided<[20, 4, 1]>>, vector<2xindex>,
      vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

// Verify that gather on a 2D memref delinearizes the gather index.
// With zero base offsets, the linearize and addi fold away.

// CHECK-LABEL: @gather_memref_2d_delinearize
// CHECK-SAME:    (%[[BASE:.+]]: memref<4x2xf32>,
// CHECK-SAME:     %[[IDXVEC:.+]]: vector<4xi32>,
// CHECK-SAME:     %[[MASK:.+]]: vector<4xi1>,
// CHECK-SAME:     %[[PASS:.+]]: vector<4xf32>)
// CHECK-DAG:     %[[IDXS:.+]] = arith.index_cast %[[IDXVEC]]
//
// CHECK-DAG:     %[[IDX0:.+]] = vector.extract %[[IDXS]][0]
// CHECK:         %[[DL0:.+]]:2 = affine.delinearize_index %[[IDX0]] into (4, 2)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%[[DL0]]#0, %[[DL0]]#1] : memref<4x2xf32>, vector<1xf32>
//
// CHECK:         %[[IDX1:.+]] = vector.extract %[[IDXS]][1]
// CHECK:         affine.delinearize_index %[[IDX1]] into (4, 2)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%{{.+}}, %{{.+}}] : memref<4x2xf32>, vector<1xf32>
//
// CHECK:         %[[IDX2:.+]] = vector.extract %[[IDXS]][2]
// CHECK:         affine.delinearize_index %[[IDX2]] into (4, 2)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%{{.+}}, %{{.+}}] : memref<4x2xf32>, vector<1xf32>
//
// CHECK:         %[[IDX3:.+]] = vector.extract %[[IDXS]][3]
// CHECK:         affine.delinearize_index %[[IDX3]] into (4, 2)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%{{.+}}, %{{.+}}] : memref<4x2xf32>, vector<1xf32>
func.func @gather_memref_2d_delinearize(
    %base: memref<4x2xf32>,
    %v: vector<4xi32>, %mask: vector<4xi1>,
    %pass_thru: vector<4xf32>) -> vector<4xf32> {
  %c0 = arith.constant 0 : index
  %0 = vector.gather %base[%c0, %c0][%v], %mask, %pass_thru
    : memref<4x2xf32>, vector<4xi32>,
      vector<4xi1>, vector<4xf32> into vector<4xf32>
  return %0 : vector<4xf32>
}

// -----

// Verify that gather on a 2D memref with non-zero base offsets correctly
// incorporates the offsets via linearize + add + delinearize.

// CHECK-LABEL: @gather_memref_2d_delinearize_nonzero_offsets
// CHECK-SAME:    (%[[BASE:.+]]: memref<4x2xf32>,
// CHECK-SAME:     %[[OFF0:.+]]: index, %[[OFF1:.+]]: index,
// CHECK-SAME:     %[[IDXVEC:.+]]: vector<2xi32>,
// CHECK-SAME:     %[[MASK:.+]]: vector<2xi1>,
// CHECK-SAME:     %[[PASS:.+]]: vector<2xf32>)
// CHECK-DAG:     %[[IDXS:.+]] = arith.index_cast %[[IDXVEC]]
// CHECK:         %[[LIN:.+]] = affine.linearize_index [%[[OFF0]], %[[OFF1]]] by (4, 2)
// CHECK:         %[[IDX0:.+]] = vector.extract %[[IDXS]][0]
// CHECK:         %[[FLAT:.+]] = arith.addi %[[LIN]], %[[IDX0]]
// CHECK:         %[[DL:.+]]:2 = affine.delinearize_index %[[FLAT]] into (4, 2)
// CHECK:         scf.if
// CHECK:           vector.load %[[BASE]][%[[DL]]#0, %[[DL]]#1]
func.func @gather_memref_2d_delinearize_nonzero_offsets(
    %base: memref<4x2xf32>,
    %off0: index, %off1: index,
    %v: vector<2xi32>, %mask: vector<2xi1>,
    %pass_thru: vector<2xf32>) -> vector<2xf32> {
  %0 = vector.gather %base[%off0, %off1][%v], %mask, %pass_thru
    : memref<4x2xf32>, vector<2xi32>,
      vector<2xi1>, vector<2xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}
