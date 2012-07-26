# -------------------------------------------------
# Project created by QtCreator 2012-05-20T13:24:18
# -------------------------------------------------
QT += webkit
QT += gui
QT += network
TARGET = qt_webkit
CONFIG += staticlib
CONFIG -= app_bundle
CONFIG += create_prl
CONFIG += link_prl

TEMPLATE = lib
SOURCES += Webkit.cpp
HEADERS += Webkit.h \
    CallbackPage.h \
    MyLooksStyle.h

#QMAKE_CXXFLAGS += -ggdb
#QMAKE_CXXFLAGS += -static
