import mqtt
import string
import json

class lv_sp1 : lv.btn
  var parent
  var delay

  var b_label
  var v_topic
  var v_state 
  var v_values
 
  def init(parent)
    super(self).init(parent)
    self.parent=parent
    self.set_width(parent.get_width())
    self.set_pos(0, 0)

    self.v_topic = ""
    self.v_values= {}
    self.v_state = 2 # (0: off, 1: on, 2: offline)
    
    self.b_label=lv.label(self)
    self.b_label.set_text("offline")
    self.b_label.set_align(lv.ALIGN_BOTTOM_MID)
    self.b_label.set_pos(0,4)

    self.delay = 1

    # self.add_event_cb(/->self.before_del(), lv.EVENT_DELETE, 0)   # register `before_del` to be called when object is deleted
    self.add_event_cb(/->self.clicked_cb(), lv.EVENT_SHORT_CLICKED, 0) # register click
    self.add_event_cb(/->self.long_cb(), lv.EVENT_LONG_PRESSED, 0) # register click

    # no regular action needed
    # tasmota.add_driver(self)
  end

  def add(topic)
    if mqtt.connected()
      self.v_topic = topic
      mqtt.subscribe("+/"+topic+"/#",/ topic,idx,payload_s,payload_b -> self.recv(topic,idx,payload_s,payload_b))
      mqtt.publish("cmnd/"+topic+'/POWER','')
      mqtt.publish("cmnd/"+topic+'/STATUS','8')
      mqtt.publish("cmnd/"+topic+'/TelePeriod','30')
    else
      tasmota.set_timer(5000,/-> self.add(topic))
    end
  end

  def print()
    print("topic: "+self.v_topic)
    print("state: "+self.v_state)
    print("values: "+self.v_values)
  end

  def recv(topic,idx,payload_s,payload_b)
    # print("topic:   ",topic)
    # print("payload: ",payload_s)
    var t=string.split(topic,"/",2)[-1]
    # print("t:       ",t)
    # power on/off
    if t=='POWER'
      if payload_s=="ON"
        # print("State change! ON!!")
        self.v_state=1
      elif payload_s=="OFF"
        # print("State change! OFF!!")
        self.v_state=0
      end
    elif (t=="STATE")
      var j=json.load(payload_s)
      var pow=j.find('POWER')
      if pow=="ON"
        # print("STATE change! ON!!")
        self.v_state=1
      elif pow=="OFF"
        # print("STATE change! OFF!!")
        self.v_state=0
      end
    elif (t=="STATUS8")
      var j=json.load(payload_s)
      self.v_values=j.find('StatusSNS',[]).find('ENERGY')
      # print("Energy:",self.v_values)
    elif (t=="SENSOR")
      var j=json.load(payload_s)
      self.v_values=j.find('ENERGY')
      # print("EnergY:",self.v_values)
    elif (t=="LWT" && payload_s=="offline")
      # print("Offline")
      self.v_state=2
    end
    self.show()
    return true
  end

  def clicked_cb()
    var msg="ON"
    if self.v_state==1
      msg="OFF"
    end
    mqtt.publish('cmnd/'+self.v_topic+'/POWER',msg)
    tasmota.set_timer(1000,/-> mqtt.publish('cmnd/'+self.v_topic+'/STATUS',"8"))

  end

  def show()
    var bg=0
    var text=0xffffff # default white
    var b="" # Power label
    if self.v_state==1 #  is on
      bg=0xffffff
      text=0
      b=string.format("%3dW",self.v_values.find('Power'))
      if b==nil || b=="W" b="unbekannt" end
    elif self.v_state==2
      b="offline"
    end
    self.set_style_bg_color(lv.color(bg), lv.PART_MAIN | lv.STATE_DEFAULT)
    self.set_style_text_color(lv.color(text), lv.PART_MAIN | lv.STATE_DEFAULT)
    self.b_label.set_text(b)

    # lv.disp().trig_activity()
  end

end

return lv_sp1