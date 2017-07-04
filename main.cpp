#include <QtDebug>
#include <gtest/gtest.h>

TEST(Foo, FooTest) {
    qDebug() << "FooTest called...";
    ASSERT_TRUE(true);
}

int main(int argc, char *argv[]) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
