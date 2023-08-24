use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A composite sampler

package OpenTelemetry::SDK::Trace::Sampler::ParentBased;

our $VERSION = '0.001';

class OpenTelemetry::SDK::Trace::Sampler::ParentBased
    :does(OpenTelemetry::SDK::Trace::Sampler)
{
    use OpenTelemetry::Trace;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOff;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOn;

    field $root                      :param;
    field $remote_parent_sampled     :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new;
    field $remote_parent_not_sampled :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new;
    field $local_parent_sampled      :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new;
    field $local_parent_not_sampled  :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new;

    method description () {
        sprintf 'ParentBased{root=%s,remote_parent_sampled=%s,remote_parent_not_sampled=%s,local_parent_sampled=%s,local_parent_not_sampled=%s}',
            map $_->description,
                $root,
                $remote_parent_sampled,
                $remote_parent_not_sampled,
                $local_parent_sampled,
                $local_parent_not_sampled;
    }

    method should_sample (%args) {
        my $span_context = OpenTelemetry::Trace
            ->span_from_context($args{context})->context;

        my $sampled = $span_context->trace_flags->sampled;

        my $delegate = !$span_context->valid
            ? $root
            : $span_context->remote
                ? $sampled
                    ? $remote_parent_sampled
                    : $remote_parent_not_sampled
                : $sampled
                    ? $local_parent_sampled
                    : $local_parent_not_sampled;

        $delegate->should_sample(%args);
    }
}

__END__

=encoding UTF-8

=head1 NAME

OpenTelemetry::SDK::Trace::Sampler::ParentBased - A composite sampler

=head1 SYNOPSIS

    my $sampler = OpenTelemetry::SDK::Trace::Sampler->new(
        ParentBased => ( root => $parent_sampler )
    );

    my $result = $sampler->should_sample( ... );

    if ( $result->sampled ) {
        ...
    }

=head1 DESCRIPTION

This module provides a sampler whose
L<should_sample|OpenTelemetry::SDK::Trace::Sampler/should_sample> method
will always return a L<result|OpenTelemetry::SDK::Trace::Sampler::Result> that
is neither sampled nor recording.

=head1 METHODS

This class implements the L<OpenTelemetry::SDK::Trace::Sampler> role.
Please consult that module's documentation for details on the behaviours it
provides.

=head2 new

    $sampler = OpenTelemetry::SDK::Trace::Sampler::ParentBased->new(
        root                      => $root,
        remote_parent_sampled     => $remote_sampled     // AlwaysOn,
        remote_parent_not_sampled => $remote_not_sampled // AlwaysOff,
        local_parent_sampled      => $local_sampled      // AlwaysOn,
        local_parent_not_sampled  => $local_not_sampled  // AlwaysOff,
    );

Takes a number of samplers on which the sampling decision will be delegated
depending on the span in question. The delegate samplers will be used in the
following cases:

=over

=item root

Used for spans without a parent, or "root" spans.

=item remote_parent_sampled

Used for spans with a remote parent that is flagged as sampled.

=item remote_parent_not_sampled

Used for spans with a remote parent that is not flagged as sampled.

=item local_parent_sampled

Used for spans with a local parent that is flagged as sampled.

=item local_parent_not_sampled

Used for spans with a local parent that is not flagged as sampled.

=back

The span's L<OpenTelemetry::Trace::SpanContext> is used to determine the above
cases. A span is a root span when calling
L<invalid|OpenTelemetry::Trace::SpanContext/invalid> on it returns true.
A span's parent is remote when calling
L<remote|OpenTelemetry::Trace::SpanContext/remote> on the span context returns
true, and sampled when calling
L<sampled|OpenTelemetry::Propagator::TraceContext::TraceFlags|/sampled> on the
associated L<OpenTelemetry::Propagator::TraceContext::TraceFlags> returns
true.

Of these parameters, only the C<root> sampler is required. If not provided,
the rest will default to the L<OpenTelemetry::SDK::Trace::Sampler::AlwaysOn>
sampler for sampled spans, and the
L<OpenTelemetry::SDK::Trace::Sampler::AlwaysOff> sampler for not sampled
spans.

=head2 description

    $string = $sampler->description;

Returns a string starting with C<ParentBased> and composed of the descriptions
of the individual samplers this sampler is composed of.

=head2 should_sample

    $result = $sampler->should_sample(
        context    => $context,
        trace_id   => $trace_id,
        kind       => $span_kind,
        name       => $span_name,
        attributes => \%attributes,
        links      => \@links,
    );

This method will read the span from the L<OpenTelemetry::Context> object
provided in the C<context> key (or the current context, if none is provided)
and delegate this sampling decision to the sampler that has been configured
for that span depending on whether it is a root span, whether it has a remote
parent, and whether it is sampled, as described above.

Any additional parameters passed to this method will be forwarded to the
delegated sampler.

=head1 SEE ALSO

=over

=item L<OpenTelemetry::Context>

=item L<OpenTelemetry::Propagator::TraceContext::TraceFlags>

=item L<OpenTelemetry::SDK::Trace::Sampler::AlwaysOff>

=item L<OpenTelemetry::SDK::Trace::Sampler::AlwaysOn>

=item L<OpenTelemetry::SDK::Trace::Sampler::Result>

=item L<OpenTelemetry::SDK::Trace::Sampler>

=item L<OpenTelemetry::Trace::SpanContext>

=back

=head1 COPYRIGHT AND LICENSE

...
