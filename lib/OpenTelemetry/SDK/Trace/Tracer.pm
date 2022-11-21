use Object::Pad;
# ABSTRACT: A Tracer for the OpenTelemetry SDK

package OpenTelemetry::SDK::Trace::Tracer;

our $VERSION = '0.001';

class OpenTelemetry::SDK::Trace::Tracer :isa(OpenTelemetry::Trace::Tracer) {
    has $name         :param;
    has $version      :param;
    has $span_creator :param;

    method create_span ( %args ) {
        $args{name}    //= 'empty';
        $args{kind}    //= 'internal';

        $args{context} = OpenTelemetry::Context->current
            unless exists $args{context};

        $span_creator->(%args);
    }
}
