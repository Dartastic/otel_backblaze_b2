// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_backblaze_b2_suppression.dart';

const _tracerName = 'dartastic_otel_libs_backblaze_b2';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class BackblazeB2Result {
  const BackblazeB2Result({
    this.api,
    this.bucketId,
    this.bucketType,
    this.fileId,
    this.bytes,
    this.parts,
    this.cloudFlareCacheHit,
    this.region,
    this.requestId,
    this.statusCode,
  });

  /// `s3` (S3-compatible API) / `native` (b2 native).
  final String? api;

  /// Bucket id.
  final String? bucketId;

  /// `allPublic` / `allPrivate` / `snapshot` — affects download
  /// billing (public via Bunny/CF is free egress).
  final String? bucketType;

  /// `fileId`.
  final String? fileId;

  /// Object bytes.
  final int? bytes;

  /// Parts uploaded for a large-file upload (B2 large-file is a
  /// distinct API class).
  final int? parts;

  /// Whether the response came via Cloudflare Bandwidth Alliance
  /// (free egress through partner CDN).
  final bool? cloudFlareCacheHit;

  /// `us-west-001` / `us-west-002` / `us-west-004` / `eu-central-003`.
  final String? region;

  /// `X-Bz-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class BackblazeB2CallResult<T> {
  const BackblazeB2CallResult({required this.value, this.result});
  final T value;
  final BackblazeB2Result? result;
}

/// Wraps a Backblaze B2 API call in a CLIENT span. [operation] is one
/// of `b2_authorize_account`, `b2_list_buckets`, `b2_create_bucket`,
/// `b2_update_bucket`, `b2_list_file_names`, `b2_list_file_versions`,
/// `b2_get_upload_url`, `b2_upload_file`, `b2_download_file_by_id`,
/// `b2_download_file_by_name`, `b2_delete_file_version`,
/// `b2_copy_file`, `b2_start_large_file`, `b2_get_upload_part_url`,
/// `b2_upload_part`, `b2_finish_large_file`, `b2_cancel_large_file`,
/// `b2_create_key`, `b2_list_keys`.
Future<T> tracedBackblazeB2<T>({
  required String operation,
  required Future<BackblazeB2CallResult<T>> Function() invoke,
  String? api,
}) async {
  if (backblazeB2InstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'backblaze_b2',
    'rpc.method': operation,
    'backblaze_b2.operation': operation,
  };
  if (api != null) m['backblaze_b2.api'] = api;

  final span = _tracer().startSpan(
    'backblaze_b2 $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.api != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.api',
          r.result!.api!,
        ));
      }
      if (r.result!.bucketId != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.bucket.id',
          r.result!.bucketId!,
        ));
      }
      if (r.result!.bucketType != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.bucket.type',
          r.result!.bucketType!,
        ));
      }
      if (r.result!.fileId != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.file.id',
          r.result!.fileId!,
        ));
      }
      if (r.result!.bytes != null) {
        extras.add(OTel.attributeInt(
          'backblaze_b2.bytes',
          r.result!.bytes!,
        ));
      }
      if (r.result!.parts != null) {
        extras.add(OTel.attributeInt(
          'backblaze_b2.parts',
          r.result!.parts!,
        ));
      }
      if (r.result!.cloudFlareCacheHit != null) {
        extras.add(OTel.attributeBool(
          'backblaze_b2.bandwidth_alliance.hit',
          r.result!.cloudFlareCacheHit!,
        ));
      }
      if (r.result!.region != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.region',
          r.result!.region!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'backblaze_b2.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Backblaze B2 HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
