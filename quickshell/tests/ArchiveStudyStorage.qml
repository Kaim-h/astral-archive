import QtQuick
import QtQuick.LocalStorage
import "../archive/ArchiveCheckpoint.mjs" as Checkpoint

// Standalone synthetic study only. No arbitrary paths, real files, startup
// restore or background writes. One explicit slot, transactionally replaced.
QtObject {
    id:store
    property string databaseName:"AstralArchive.NativeStudy.Checkpoint"
    function database(){
        return LocalStorage.openDatabaseSync(databaseName,"1.0","Astral Archive isolated synthetic checkpoint",4000000)
    }
    function write(payload){
        Checkpoint.decode(payload)
        database().transaction(function(tx){
            tx.executeSql("CREATE TABLE IF NOT EXISTS checkpoint (slot INTEGER PRIMARY KEY CHECK(slot=1), payload TEXT NOT NULL)")
            tx.executeSql("INSERT OR REPLACE INTO checkpoint(slot,payload) VALUES(1,?)",[payload])
        })
    }
    function read(){
        var payload=null
        database().readTransaction(function(tx){
            var table=tx.executeSql("SELECT name FROM sqlite_master WHERE type='table' AND name='checkpoint'")
            if(!table.rows.length)return
            var row=tx.executeSql("SELECT payload FROM checkpoint WHERE slot=1")
            if(row.rows.length)payload=String(row.rows.item(0).payload)
        })
        // Refuse corrupt/unsupported storage before the caller imports it.
        if(payload!==null)Checkpoint.decode(payload)
        return payload
    }
}
