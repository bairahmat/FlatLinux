/* { dg-do run } */
/* { dg-options "-O2 -mavx512f" } */
/* { dg-require-effective-target avx512f } */

#define AVX512F

#include "avx512f-helper.h"

#define SIZE (AVX512F_LEN / 32)
#include "avx512f-mask-type.h"


CALC (int *src1, int *src2, int *dst)
{
  int i;

  for (i = 0; i < SIZE; i++)
    dst[i] = src1[i] > src2[i] ? src1[i] : src2[i];
}

void static
TEST (void)
{
  int i, sign;
  UNION_TYPE (AVX512F_LEN, i_d) src1, src2, res1, res2, res3;
  MASK_TYPE mask = MASK_VALUE;
  int res_ref[SIZE];

  for (i = 0; i < SIZE; i++)
    {
      src1.a[i] =  i * sign;
      src2.a[i] = (i + 2000) * sign;
      sign = -sign;
      res2.a[i] = DEFAULT_VALUE;
    }

  res1.x = INTRINSIC (_max_epi32) (src1.x, src2.x);
  res2.x = INTRINSIC (_mask_max_epi32) (res2.x, mask, src1.x, src2.x);
  res3.x = INTRINSIC (_maskz_max_epi32) (mask, src1.x, src2.x);

  CALC (src1.a, src2.a, res_ref);

  if (UNION_CHECK (AVX512F_LEN, i_d) (res1, res_ref))
    abort ();

  MASK_MERGE (i_d) (res_ref, mask, SIZE);
  if (UNION_CHECK (AVX512F_LEN, i_d) (res2, res_ref))
    abort ();

  MASK_ZERO (i_d) (res_ref, mask, SIZE);
  if (UNION_CHECK (AVX512F_LEN, i_d) (res3, res_ref))
    abort ();
}