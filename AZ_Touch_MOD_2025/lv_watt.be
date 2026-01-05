import mqtt
import string
import json

class lv_watt : lv.label
  var parent
  var delay

  var v_topic
  var v_json
  var v_fmt
 
  def init(parent)
    super(self).init(parent)
    self.parent=parent

    self.v_topic = ""
    self.v_json = nil
    self.v_fmt = nil

    self.delay = 1
  end

  def add(topic,json,fmt)
    self.v_topic = topic
    self.v_json = json
    self.v_fmt = fmt
    mqtt.subscribe(topic,/ topic,idx,payload_s,payload_b -> self.recv(topic,idx,payload_s,payload_b))
  end

  def print()
    print("topic: ",self.v_topic)
    print("json: ",self.v_json)
    print("format: ",self.v_fmt)
  end

  def recv(topic,idx,payload_s,payload_b)
    # print("topic:   ",topic)
    print("payload: ",payload_s)
    # print("t:       ",t)
    # power on/off
    var pw
    if self.v_json==nil
      pw=payload_s
    else
      var j=json.load(payload_s)
      j=j.find(string.split(self.v_json,"/")[0])
      if string.split(self.v_json,"/").size() < 2
        pw=j
      else 
        pw=j.find(string.split(self.v_json,"/")[1])
      end
    end
    if self.v_fmt == nil
      self.set_text(pw)
    else
      self.set_text(format(self.v_fmt,pw))
    end
    #  var j=json.load(payload_s)
    #  var pow=j.find('POWER')
    #  if pow==nil
    #    pow=j.find('POWER1')
    #  end
    return true
  end

end

return lv_watt
