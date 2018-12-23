module aurora.framework.collections;

import core.atomic;
import std.typecons;

public shared class ConcurrentStack(T) {
    private shared struct Node {
        public T _payload;
        public Node* _next;

        public this(T value) {
            this._payload = value;
            this._next = null;
        }
    }
    private Node* _root = null;

    void push(T value) {
        auto n = new Node(value);
        shared(Node)* oldRoot;
        do {
            oldRoot = _root;
            n._next = oldRoot;
        } while(!cas(&_root, oldRoot, n));
    }

    Nullable!(shared(T)) pop() {
        typeof(return) result;
        shared(Node)* oldRoot;
        do {
            oldRoot = _root;
            if (!oldRoot) return Nullable!(shared(T));
            result = oldRoot._payload;
        } while(!cas(&_root, oldRoot, oldRoot._next));
        return result;
    }
}

public shared class ConcurrentQueue(T) {
    private shared struct Node {
        public T _payload;
        public Node* _next;

        public this(T value) {
            this._payload = cast(shared(T))value;
            this._next = null;
        }
    }
    private Node* _head = null;
    private Node* _tail = null;

    void enqueue(T value) {
        auto n = new Node(value);
        bool updatedLink = false;

        while(!updatedLink) {
            shared(Node)* oldTail = _tail;
            shared(Node)* oldNext = oldTail._next;

            if (oldTail == _tail) {
                if (oldNext == null) {
                    updatedLink = cas(&_tail._next, cast(shared(Node)*)null, n);
                } else {
                    cas(&_tail, oldTail, oldNext);
                }
                cas(&_tail, oldTail, n);
            }
        }
    }

    shared(T)* dequeue() {
        typeof(return) result;
        bool headAdvanced = false;

        while(!headAdvanced) {
            shared(Node)* oldHead = _head;
            shared(Node)* oldTail = _tail;
            shared(Node)* oldHeadNext = oldHead._next;

            if (oldHead == _head) {
                if (oldHead == oldTail) {
                    if (oldHeadNext == null) {
                        return null;
                    }
                    cas(&_tail, oldTail, oldHeadNext);
                } else {
                    result = &oldHeadNext._payload;
                    headAdvanced = cas(&_head, oldHead, oldHeadNext);
                }
            }
        }
        return result;
    }
}