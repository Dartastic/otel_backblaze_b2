// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_backblaze_b2/otel_backblaze_b2.dart';

/// Traces Backblaze B2 calls with OpenTelemetry.
///
/// `otel_backblaze_b2` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Backblaze B2 call in
/// [tracedBackblazeB2]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'backblaze-b2-example');

  // Wraps a Backblaze B2 API call in a CLIENT span.
  final backblazeB2Id = await tracedBackblazeB2<String>(
    operation: 'create',
    api: 'example',
    invoke: () async {
      // Make the Backblaze B2 call here, then report what it returned.
      const id = 'backblaze_b2_8f3a2c';
      return const BackblazeB2CallResult(
          value: id,
          result: BackblazeB2Result(
              api: 's3',
              bucketId: 'bucket_8f3a2c',
              bucketType: 'allPublic',
              fileId: 'file_8f3a2c',
              bytes: 512,
              parts: 1,
              cloudFlareCacheHit: true,
              region: 'us-west-001',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedBackblazeB2 create returned $backblazeB2Id');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBackblazeB2InstrumentationAsync.
  await runWithoutBackblazeB2InstrumentationAsync(
    () => tracedBackblazeB2<String>(
      operation: 'create',
      api: 'example',
      invoke: () async {
        const id = 'backblaze_b2_8f3a2c';
        return const BackblazeB2CallResult(
            value: id,
            result: BackblazeB2Result(
                api: 's3',
                bucketId: 'bucket_8f3a2c',
                bucketType: 'allPublic',
                fileId: 'file_8f3a2c',
                bytes: 512,
                parts: 1,
                cloudFlareCacheHit: true,
                region: 'us-west-001',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
