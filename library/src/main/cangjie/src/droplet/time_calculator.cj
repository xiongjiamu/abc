/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



public class TimeStamp <: ToString {
    public TimeStamp(var mills!: Int64 = DateTime.now().nanosecond, var msg!: String = "") {

    }

    public operator func -(ts: TimeStamp): TimeStamp {
        let t = TimeStamp()
        t.mills = this.mills - ts.mills
        t.msg = "diff"
        return t
    }

    public func toString(): String {
        return "${msg} : ${mills} ns"
    }
}

public class TimeCalculator {
    public static var timeList: ArrayList<TimeStamp> = ArrayList() 
    public static var num: Int64 = 0

    public static func debug() {
        debug("timecalc - ${num}")
    }

    public static func debug(msg: String) {
        timeList.append(TimeStamp(msg: "${msg} - ${num}"))
    }

    public static func calcRes() {
        if(timeList.isEmpty()) {
            return
        }
        var o0: TimeStamp = timeList.get(0).getOrThrow()
        timeList.remove(0)
        var o1: TimeStamp
        var it = timeList.iterator()
        while (true) {
            match (it.next()) {
                case Some(o) => 
                    o1 = o
                    o0 = o1
                case None => break
            }
        }
    }
}
