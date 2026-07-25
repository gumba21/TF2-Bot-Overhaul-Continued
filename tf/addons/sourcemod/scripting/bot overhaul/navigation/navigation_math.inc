#if defined _navigation_math_inc
 #endinput
#endif
#define _navigation_math_inc

float FloatMin(float first, float second)
{
    return first < second ? first : second;
}

float FloatMax(float first, float second)
{
    return first > second ? first : second;
}
