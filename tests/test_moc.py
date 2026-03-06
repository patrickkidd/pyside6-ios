import re

from pyside6_ios.moc import Q_OBJECT_RE


def test_detects_q_object():
    src = "class Foo : public QObject {\n    Q_OBJECT\npublic:\n};"
    assert Q_OBJECT_RE.search(src)


def test_ignores_non_q_object():
    src = "class Foo {};\nint Q_OBJECT_NOT = 1;"
    assert not Q_OBJECT_RE.search(src)


def test_ignores_commented_q_object():
    src = "// Q_OBJECT\nclass Foo {};"
    assert not Q_OBJECT_RE.search(src)
