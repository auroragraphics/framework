module aurora.framework.binding;

import core.sync.rwmutex;
import std.variant;

import aurora.framework.collections;

public final shared class BindingProperty {
    private string _name;
    public @property string Name() { return _name; }
}

public abstract shared class BindingObject {
    private shared class Updated {
        public Variant _value;
        public string _property;

        public this(Variant value, string property) {
            this._value = cast(shared)value;
            this._property = property;
        }
    }
    private Variant[string] values;
    private ConcurrentQueue!Updated updates;
    private ReadWriteMutex mutex;

    public this() {
        updates = new ConcurrentQueue!Updated();
        mutex = cast(shared) new ReadWriteMutex(ReadWriteMutex.Policy.PREFER_WRITERS);
    }

    public T GetValue(T)(BindingProperty property) {
        rwmutex.Reader.lock();
        scope(exit) rwmutex.Reader.unlock();
        return values[property.Name].get!T();
    }

    public void SetValue(T)(BindingProperty property, T value) {
        updates.enqueue(new Updated(Variant(T), property.Name));
    }

    package void ApplyUpdates() {
        rwmutex.Writer.lock();
        scope(exit) rwmutex.Writer.unlock();

        Updated* t = updates.dequeue();
        while (t !is null) {

            t = updates.dequeue();
        }
    }
}