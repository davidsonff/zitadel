import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';

import { AppModule } from './app/app.module';

// Compatibility shim: the buf.build/protocolbuffers/js plugin emits calls to
// BinaryReader.prototype.readStringRequireUtf8 / BinaryWriter.prototype.writeStringRequireUtf8,
// which only exist in the newer `protobuf-javascript` runtime. The pinned
// `google-protobuf@3.21.x` runtime never had them, so we alias them to the
// non-validating readString/writeString to prevent runtime TypeErrors.
// See: https://github.com/protocolbuffers/protobuf-javascript
// eslint-disable-next-line @typescript-eslint/no-var-requires
const jspb = require('google-protobuf');
if (jspb?.BinaryReader && !jspb.BinaryReader.prototype.readStringRequireUtf8) {
  jspb.BinaryReader.prototype.readStringRequireUtf8 = jspb.BinaryReader.prototype.readString;
}
if (jspb?.BinaryWriter && !jspb.BinaryWriter.prototype.writeStringRequireUtf8) {
  jspb.BinaryWriter.prototype.writeStringRequireUtf8 = jspb.BinaryWriter.prototype.writeString;
}

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .catch((err) => console.error(err));
