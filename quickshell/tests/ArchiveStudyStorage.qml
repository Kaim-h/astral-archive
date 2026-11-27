import QtQuick
import QtQuick.LocalStorage
import "../archive/ArchiveCheckpoint.mjs" as Checkpoint

// Standalone synthetic study only. No arbitrary paths, real files or
// automatic arrangement restore. Explicit checkpoint and preference slots.
QtObject {
    id:store
    property string databaseName:"AstralArchive.NativeStudy.Checkpoint"
    function database(){
        return LocalStorage.openDatabaseSync(databaseName,"1.0","Astral Archive isolated synthetic checkpoint",4000000)
    }
    // Separate single global view preference; does not write an arrangement.
    function writeRoomPerspective(value){
        if(typeof value!=="boolean")throw Error("Invalid Room projection preference")
        database().transaction(function(tx){
            tx.executeSql("CREATE TABLE IF NOT EXISTS room_preference (slot INTEGER PRIMARY KEY CHECK(slot=1), perspective INTEGER NOT NULL CHECK(perspective IN (0,1)))")
            tx.executeSql("INSERT OR REPLACE INTO room_preference(slot,perspective) VALUES(1,?)",[value?1:0])
        })
    }
    function readRoomPerspective(){
        var value=false
        database().readTransaction(function(tx){
            var table=tx.executeSql("SELECT name FROM sqlite_master WHERE type='table' AND name='room_preference'")
            if(!table.rows.length)return
            var row=tx.executeSql("SELECT perspective FROM room_preference WHERE slot=1")
            if(row.rows.length){
                var stored=Number(row.rows.item(0).perspective)
                if(stored!==0&&stored!==1)throw Error("Invalid stored Room projection preference")
                value=stored===1
            }
        })
        return value
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
