//#define TEST_NO_MAIN
#include "../acutest.h"
#include "../include/external.h"

void test_add(void)
{
    TEST_CHECK(external_add(1, 2) == 3);
}

TEST_LIST =
{
    { "test_add", test_add },
    { NULL, NULL },
};

