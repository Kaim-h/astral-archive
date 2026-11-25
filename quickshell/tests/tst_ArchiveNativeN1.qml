import QtQuick
import QtTest
import "../archive" as Archive
import "../archive/ArchiveCore.mjs" as Core

Item {
    width: 640
    height: 480
    Archive.ArchiveModel { id: archive }
    TestCase {
        name: "ArchiveNativeN1"
        function init() { archive.reset(Core.fixture()) }
        function test_core_and_worker() {
            var original = JSON.stringify(archive.snapshot)
            var m = Core.rackAt(archive.snapshot, "root", "rack-1")
            compare(Core.validate(archive.snapshot), null)
            archive.stage("root", m.id, {r: 52})
            compare(archive.preview.rack.r, 52)
            archive.stage("root", m.id, {r: 38})
            compare(archive.preview.rack.r, 38)
            compare(JSON.stringify(archive.snapshot), original)
            tryCompare(archive, "phase", "attention", 15000)
            var cells = Core.geometry(Object.assign({}, m, {r: 38})).cells
            var dest = cells.find(function(c) { return c.key !== "1:1" && c.area > 3600 }).key
            archive.choose("test-b", "case")
            compare(archive.preview.caseOverflow.length, 1)
            archive.choose("test-c", dest)
            tryCompare(archive, "phase", "ready", 15000)
            verify(archive.radiusApprovalRequired)
            verify(!archive.apply())
            archive.approveRadius(true)
            verify(archive.apply())
            compare(archive.snapshot.caseItems.length, 1)
            compare(Core.rackAt(archive.snapshot, "root", m.id).r, 38)
            verify(archive.undo())
            compare(JSON.stringify(archive.snapshot), original)
        }
        function test_depth_only_reflow() {
            verify(archive.paintCell("root","rack-1","-1:3",null,20))
            var before=JSON.stringify(archive.snapshot)
            var meta=Core.rackAt(archive.snapshot,"root","rack-1").cellMeta["-1:3"]
            archive.stage("root","rack-1",{w:400,h:320})
            tryCompare(archive,"phase","attention",15000)
            verify(!archive.apply())
            compare(JSON.stringify(archive.snapshot),before)
            var issue=archive.draft.result.review.find(function(r){return r.cellId===meta.id})
            verify(!!issue&&issue.options.indexOf("0:0")>=0)
            archive.choose("paint:"+meta.id,"0:0")
            tryCompare(archive,"phase","ready",15000)
            verify(archive.apply())
            var moved=Core.rackAt(archive.snapshot,"root","rack-1").cellMeta["0:0"]
            compare(moved.id,meta.id);compare(moved.depth,20);compare(moved.color,null)
            verify(archive.undo());compare(JSON.stringify(archive.snapshot),before)
            archive.stage("root","rack-1",{w:400,h:320})
            tryCompare(archive,"phase","attention",15000)
            archive.choose("paint:"+meta.id,"discard")
            tryCompare(archive,"phase","ready",15000)
            archive.cancel();compare(JSON.stringify(archive.snapshot),before)
        }
        function test_cancel_stale() {
            var original = JSON.stringify(archive.snapshot)
            archive.stage("root", "rack-1", {r: 38})
            // Let an actual WorkerScript message become outstanding.
            tryVerify(function() { return archive.runningRevision !== -1 || archive.phase !== "pending" }, 5000)
            archive.cancel()
            archive.stage("root", "rack-1", {r: 75})
            tryCompare(archive, "phase", "ready", 15000)
            verify(archive.draft.result.unchanged)
            archive.cancel()
            compare(JSON.stringify(archive.snapshot), original)
        }
        function test_synthetic_group() {
            var original = Core.fixture()
            var moved = Core.transfer(Core.session(original), ["test-a", "test-b"], "case")
            compare(moved.error, "")
            compare(moved.snapshot.caseItems.length, 2)
            compare(JSON.stringify(Core.undo(moved).snapshot), JSON.stringify(original))
        }
    }
}
