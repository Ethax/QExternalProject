TEMPLATE = app
QT += core
QT -= gui

CONFIG += c++14 console
CONFIG -= app_bundle

include(QExternalProject.pri)
EP_BASE = $$OUT_PWD/3rdParty

GTEST_V180_DL = "https://github.com/google/googletest/archive/release-1.8.0.tar.gz"
GTEST_CONFIG_CMD = "cmake -DCMAKE_INSTALL_PREFIX=$$EP_BASE/Install/gtest"

gtest.target = googletest
gtest.commands = @ \
    $$EP_InitStep(gtest) $$EP_ENDL \
    $$EP_DownloadStep(gtest, $$GTEST_V180_DL, 1) $$EP_ENDL \
    $$EP_BuildStep(gtest, $$GTEST_CONFIG_CMD, "make -j2", "make install") $$EP_ENDL \
    echo \"$$EP_Emphasize("Completed \'gtest\'")\"

QMAKE_EXTRA_TARGETS += gtest gtest_build gtest_dl gtest_init
PRE_TARGETDEPS += googletest

GTEST_BASE = $$EP_BASE/Install/gtest

DEPENDPATH += $$GTEST_BASE/include
INCLUDEPATH += $$GTEST_BASE/include
LIBS += -L$$GTEST_BASE/lib/

TARGET = FreeTesting
SOURCES += main.cpp
LIBS += -lgtest -lgmock

# To Clean:
# https://stackoverflow.com/a/29853833/7893951

# With CMake:
# https://stackoverflow.com/a/15176075/7893951
