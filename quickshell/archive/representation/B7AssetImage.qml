import QtQuick
import "B7Layout.mjs" as Layout

// Decode original pinned SVG assets through Qt, never arbitrary file paths.
Image {
    id: art
    required property string assetId
    property bool edge: false
    // Preserve canonical SVG decoding coverage separately. Qt 6.4 renders
    // sculpture clip paths incorrectly; use the reproducibly derived PNG.
    property bool canonicalSvg:false
    readonly property var asset: Layout.assetFor(assetId)
    readonly property bool raster:!canonicalSvg&&asset.family==="sculpture"
    readonly property string relativeAsset:edge?asset.edge:asset.face
    source: Qt.resolvedUrl(raster?"../representation-raster/"+relativeAsset.replace(/\.svg$/,".png"):"../representation-assets/"+relativeAsset)
    fillMode: Image.PreserveAspectFit
    asynchronous: false
    smooth: true
    mipmap: true
}
