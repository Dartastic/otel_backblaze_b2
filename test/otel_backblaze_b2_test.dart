// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_backblaze_b2/otel_backblaze_b2.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_backblaze_b2-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('b2_upload_file records api + bucket + bytes', () async {
    await tracedBackblazeB2<String>(
      operation: 'b2_upload_file',
      api: 'native',
      invoke: () async => const BackblazeB2CallResult(
        value: 'ok',
        result: BackblazeB2Result(
          api: 'native',
          bucketId: 'b-1',
          bucketType: 'allPrivate',
          fileId: 'f-1',
          bytes: 5242880,
          region: 'us-west-004',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('backblaze_b2 b2_upload_file')!);
    expect(a['backblaze_b2.api'], 'native');
    expect(a['backblaze_b2.bucket.type'], 'allPrivate');
    expect(a['backblaze_b2.bytes'], 5242880);
    expect(a['backblaze_b2.region'], 'us-west-004');
  });

  test('large-file upload records parts', () async {
    await tracedBackblazeB2<String>(
      operation: 'b2_finish_large_file',
      invoke: () async => const BackblazeB2CallResult(
        value: 'ok',
        result: BackblazeB2Result(parts: 12, bytes: 1073741824),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('backblaze_b2 b2_finish_large_file')!,
    );
    expect(a['backblaze_b2.parts'], 12);
  });

  test('Cloudflare Bandwidth Alliance hit recorded', () async {
    await tracedBackblazeB2<String>(
      operation: 'b2_download_file_by_id',
      invoke: () async => const BackblazeB2CallResult(
        value: 'ok',
        result: BackblazeB2Result(cloudFlareCacheHit: true),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('backblaze_b2 b2_download_file_by_id')!,
    );
    expect(a['backblaze_b2.bandwidth_alliance.hit'], true);
  });

  test('suppression skips spans', () async {
    await runWithoutBackblazeB2InstrumentationAsync(() async {
      await tracedBackblazeB2<String>(
        operation: 'b2_list_buckets',
        invoke: () async => const BackblazeB2CallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('backblaze_b2 '), isEmpty);
  });
}
