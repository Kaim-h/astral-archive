// Qt WorkerScript uses an ECMAScript module, not browser Worker/Blob APIs.
import { solve } from "ArchiveCore.mjs";
WorkerScript.onMessage = function(message) {
    WorkerScript.sendMessage(solve(message));
};
