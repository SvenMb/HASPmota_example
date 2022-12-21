import mqtt
import string

class lv_tuya : lv.btn
  var parent
  var delay
  var br_label
  var topics

  var devtype         # 0: rgb 1: only white 2: only color 
  var v_state      # (0: off, 1: on, 2: offline)
  var v_mode       # (0: white, 1: colour)
  var v_brightness
  var v_ctemp
  var v_ctemp_range
  var v_cbrightness # Farbton (Grad im Farbrad)
  var v_saturation
  var v_hue

  var sl
  var sl_wbtn
  var sl_cbtn
  var slc
  var slw
  var slw_bri
  var slw_temp
  var slw_brilab
  var slw_templab
  var slc_colp
  var slc_bri
  var slc_sat
  var slc_brilab
  var slc_satlab
  
  static DEV_DEFAULT=0
  static DEV_WHITE=1
  static DEV_RGB=2



  def init(parent)
    super(self).init(parent)
    self.parent=parent
    self.set_width(parent.get_width())
    self.set_pos(0, 0)

    self.topics = []
    self.devtype=0
    self.v_state = 2
    self.v_mode = 0
    self.v_brightness = 100
    self.v_ctemp = 300
    self.v_ctemp_range=[0,100]
    self.v_cbrightness = 100
    self.v_saturation = 100
    self.v_hue = 0
    
    self.br_label=lv.label(self)
    self.br_label.set_text("offline")
    self.br_label.set_align(lv.ALIGN_BOTTOM_MID)

    self.delay = 1

    # self.add_event_cb(/->self.before_del(), lv.EVENT_DELETE, 0)   # register `before_del` to be called when object is deleted
    self.add_event_cb(/->self.clicked_cb(), lv.EVENT_SHORT_CLICKED, 0) # register click
    self.add_event_cb(/->self.long_cb(), lv.EVENT_LONG_PRESSED, 0) # register click

    # no regular action needed
    # tasmota.add_driver(self)
  end

  def add(topic)
    if mqtt.connected()
      self.topics.push(topic)
      mqtt.subscribe(topic+"/#",/ topic,idx,payload_s,payload_b -> self.recv(topic,idx,payload_s,payload_b))
      mqtt.publish(topic+'/command','get-states')
    else
      tasmota.set_timer(5000,/-> self.add(topic))
    end
  end

  def set_devtype(devtype)
    self.devtype=devtype
  end

  def print()
    print("state: "+self.v_state)
    print("mode: "+self.v_mode)
    print("white brightness: "+self.v_brightness)
    print("color temp: "+self.v_ctemp)
    print("color brightness: "+self.v_cbrightness)
    print("saturation: "+self.v_saturation)
    print("hue: "+self.v_hue)
  end

  def recv(topic,idx,payload_s,payload_b)
    # print("topic:   ",topic)
    # print("payload: ",payload_s)
    var t=string.split(topic,"/",2)[-1]
    # print("t:       ",t)
    # power on/off
    if t=='state'
      if payload_s=="ON"
        # print("State change! ON!!")
        self.v_state=1
      elif payload_s=="OFF"
        # print("State change! OFF!!")
        self.v_state=0
      end
    elif t=='status'
      if payload_s=="offline"
        self.v_state=2
      elif payload_s=="online" && self.v_state==2
        self.v_state=0
      end
    elif t=='mode_state'
      if payload_s=="white"
        # print("State change! White!!")
        self.v_mode=0
      else
        # print("State change! Colour!!")
        self.v_mode=1
      end
    elif t=='white_brightness_state'
      # print("State change! White_brightness!! ",payload_s)
      self.v_brightness=int(payload_s)
    elif t=='color_temp_state'
      # print("State change! color_temp!! ",payload_s)
      self.v_ctemp=int(payload_s)
    elif t=='color_brightness_state'
      self.v_cbrightness=int(payload_s)
    elif t=='hsb_state' || t=='hs_state'
      # print("State change! hsb/hs!! ",payload_s)
      var hsb=string.split(payload_s,",")
      if hsb.size()==3
        self.v_cbrightness=int(hsb[2])
      end
      self.v_saturation=int(hsb[1])
      self.v_hue=int(hsb[0])
    else
      # print("lv_tuya: TOPIC '"+t+"': '"+ payload_s +"' not found!")
      return false
    end
    self.show()
    return false
  end

  def clicked_cb()
    var msg="ON"
    if self.v_state==1
      msg="OFF"
    end
    for t: self.topics
      # print("topic: ",t)
      mqtt.publish(t+'/command',msg)
    end
  end


  def long_cb()
    # create settings layer
    var scr = lv.scr_act()
    self.sl=lv.lv_obj(scr)
    self.sl.clear_flag(lv.OBJ_FLAG_SCROLLABLE)
    self.sl.set_width(scr.get_width())
    self.sl.set_height(scr.get_height()-33)
    self.sl.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
    self.sl.set_style_bg_color(lv.color(lv.COLOR_GRAY/2), lv.PART_MAIN | lv.STATE_DEFAULT)
    self.sl.set_style_pad_all(0, lv.PART_MAIN | lv.STATE_DEFAULT)
    self.sl.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
    
    var r24=lv.font_embedded("robotocondensed",24)

    var close = lv.btn(self.sl)
    close.set_style_bg_color(0,0)
    close.set_style_border_width(1,0)
    close.set_style_border_color(lv.color(0xc0c0c0),0)
    close.set_size(32,32)
    close.set_pos(scr.get_width()-32,0)
    var cl_label=lv.label(close)
    cl_label.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
    cl_label.set_text(string.format("%c%c%c",0xee,0x85,0x96)) # close symbol in robotocondensed
    cl_label.center()
    close.add_event_cb(/->self.close_clicked(), lv.EVENT_SHORT_CLICKED, 0) # register click

    var l

    if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_WHITE
      # layer for white light properties
      self.slw=lv.lv_obj(self.sl)
      self.slw.set_size(320,240-65)
      self.slw.set_pos(0,32)
      self.slw.clear_flag(lv.OBJ_FLAG_SCROLLABLE)
      self.slw.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw.set_style_bg_color(lv.color(lv.COLOR_GRAY/2), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw.set_style_pad_all(0, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw.set_style_border_width(1, lv.PART_MAIN | lv.STATE_DEFAULT)

      # button to switch to white mode
      self.sl_wbtn = lv.btn(self.sl)
      self.sl_wbtn.set_style_bg_color(0,0)
      self.sl_wbtn.set_style_border_width(1,0)
      self.sl_wbtn.set_style_border_color(lv.color(0xc0c0c0),0)
      self.sl_wbtn.set_height(32)
      var wlab = lv.label(self.sl_wbtn)
      wlab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      wlab.set_text("Weiss")
      wlab.center()
      self.sl_wbtn.add_event_cb(/->self.wbtn_clicked(), lv.EVENT_CLICKED, 0)

      # white mode settings
      self.slw_bri = lv.arc(self.slw)
      self.slw_bri.set_bg_angles(180,0)
      self.slw_bri.set_align(lv.ALIGN_LEFT_MID)
      self.slw_bri.set_pos(12,32)
      self.slw_bri.set_size(140,140)
      self.slw_brilab = lv.label(self.slw_bri)
      self.slw_brilab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw_brilab.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw_brilab.center()
      self.slw_brilab.set_pos(0,-4)
      l=lv.label(self.slw_bri)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x8C)+string.char(0xB5))
      l.set_pos(-3,-4)
      l=lv.label(self.slw_bri)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x9B)+string.char(0xA8))
      l.set_align(lv.ALIGN_TOP_RIGHT)
      l.set_pos(3,-4)
      self.slw_bri.add_event_cb(/->self.slw_bri_cb(), lv.EVENT_VALUE_CHANGED, 0)
      self.slw_bri.add_event_cb(/->self.slw_bri_r_cb(), lv.EVENT_RELEASED, 0)

      self.slw_temp = lv.arc(self.slw)
      self.slw_temp.set_range(self.v_ctemp_range[0],self.v_ctemp_range[1])
      self.slw_temp.set_bg_angles(180,0)
      self.slw_temp.set_align(lv.ALIGN_RIGHT_MID)
      self.slw_temp.set_pos(-12,32)
      self.slw_temp.set_size(140,140)
      self.slw_templab = lv.label(self.slw_temp)
      self.slw_templab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw_templab.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slw_templab.center()
      self.slw_templab.set_pos(0,-4)
      l=lv.label(self.slw_temp)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x96)+string.char(0xA8))
      l.set_pos(-3,-4)
      l=lv.label(self.slw_temp)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x9C)+string.char(0x97))
      l.set_align(lv.ALIGN_TOP_RIGHT)
      l.set_pos(3,-4)
      self.slw_temp.add_event_cb(/->self.slw_temp_cb(), lv.EVENT_VALUE_CHANGED, 0)
      self.slw_temp.add_event_cb(/->self.slw_temp_r_cb(), lv.EVENT_RELEASED, 0)
    end

    if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_RGB

      # layer for color properties
      self.slc=lv.lv_obj(self.sl)
      self.slc.set_size(320,240-65)
      self.slc.set_pos(0,32)
      self.slc.clear_flag(lv.OBJ_FLAG_SCROLLABLE)
      self.slc.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc.set_style_bg_color(lv.color(lv.COLOR_GRAY/2), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc.set_style_pad_all(0, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc.set_style_border_width(1, lv.PART_MAIN | lv.STATE_DEFAULT)


      self.sl_cbtn = lv.btn(self.sl)
      self.sl_cbtn.set_style_bg_color(0,0)
      self.sl_cbtn.set_style_border_width(1,0)
      self.sl_cbtn.set_style_border_color(lv.color(0xc0c0c0),0)
      self.sl_cbtn.set_height(32)
      self.sl_cbtn.set_pos(86,0)
      var clab = lv.label(self.sl_cbtn)
      clab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      clab.set_text("Farbig")
      clab.center()
      self.sl_cbtn.add_event_cb(/->self.cbtn_clicked(), lv.EVENT_CLICKED, 0)

      # color mode settings
      self.slc_colp = lv.colorwheel(self.slc, true)
      self.slc_colp.set_mode_fixed(true)
      self.slc_colp.set_align(lv.ALIGN_LEFT_MID)
      self.slc_colp.set_pos(16,0)
      self.slc_colp.set_size(scr.get_height()-96,scr.get_height()-96)
      self.slc_colp.add_event_cb(/->self.slc_cb(), lv.EVENT_VALUE_CHANGED, 0)
      self.slc_colp.add_event_cb(/->self.slc_r_cb(), lv.EVENT_RELEASED, 0)

      self.slc_bri = lv.arc(self.slc)
      self.slc_bri.set_bg_angles(180,0)
      self.slc_bri.set_align(lv.ALIGN_TOP_RIGHT)
      self.slc_bri.set_pos(-12,12)
      self.slc_bri.set_size(120,120)
      self.slc_brilab = lv.label(self.slc_bri)
      self.slc_brilab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc_brilab.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc_brilab.center()
      self.slc_brilab.set_pos(0,-4)
      l=lv.label(self.slc_bri)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x8C)+string.char(0xB5))
      l.set_pos(-4,-4)
      l=lv.label(self.slc_bri)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x9B)+string.char(0xA8))
      l.set_align(lv.ALIGN_TOP_RIGHT)
      l.set_pos(4,-4)
      self.slc_bri.add_event_cb(/->self.slc_cb(), lv.EVENT_VALUE_CHANGED, 0)
      self.slc_bri.add_event_cb(/->self.slc_r_cb(), lv.EVENT_RELEASED, 0)

      self.slc_sat = lv.arc(self.slc)
      self.slc_sat.set_bg_angles(180,0)
      self.slc_sat.set_align(lv.ALIGN_BOTTOM_RIGHT)
      self.slc_sat.set_pos(-12,40)
      self.slc_sat.set_size(120,120)
      self.slc_satlab=lv.label(self.slc_sat)
      self.slc_satlab.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc_satlab.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.slc_satlab.center()
      self.slc_satlab.set_pos(0,-4)
      l=lv.label(self.slc_sat)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x96)+string.char(0x99))
      l.set_pos(-4,-4)
      l=lv.label(self.slc_sat)
      l.set_style_text_font(r24, lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_style_text_color(lv.color(0xffffff), lv.PART_MAIN | lv.STATE_DEFAULT)
      l.set_text(string.char(0xEE)+string.char(0x96)+string.char(0xA8))
      l.set_align(lv.ALIGN_TOP_RIGHT)
      l.set_pos(4,-4)
      self.slc_sat.add_event_cb(/->self.slc_cb(), lv.EVENT_VALUE_CHANGED, 0)
      self.slc_sat.add_event_cb(/->self.slc_r_cb(), lv.EVENT_RELEASED, 0)
    end

    self.show_sl()
  end

  def show_sl()
    if self.sl == nil return end
    if self.v_mode==0
      if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_WHITE  
        self.slw.clear_flag(lv.OBJ_FLAG_HIDDEN)
        self.sl_wbtn.set_style_bg_color(lv.color(lv.COLOR_GRAY/2), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.sl_wbtn.set_style_border_side(lv.BORDER_SIDE_TOP|lv.BORDER_SIDE_LEFT|lv.BORDER_SIDE_RIGHT,0)
        self.sl_wbtn.set_height(38)
        self.slw_bri.set_value(self.v_brightness)
        self.slw_brilab.set_text(string.format("%3d%%",self.v_brightness))
        self.slw_temp.set_value(self.v_ctemp)
        if self.v_ctemp_range[1]==100
          self.slw_templab.set_text(string.format("%3d%%",self.v_ctemp))
        else
          self.slw_templab.set_text(string.format("%3d",self.v_ctemp))
        end
      end
      if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_RGB
        self.slc.add_flag(lv.OBJ_FLAG_HIDDEN)
        self.sl_cbtn.set_style_bg_color(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.sl_cbtn.set_style_border_side(lv.BORDER_SIDE_TOP|lv.BORDER_SIDE_LEFT|lv.BORDER_SIDE_RIGHT|lv.BORDER_SIDE_BOTTOM,0)
        self.sl_cbtn.set_height(32)
      end
    else
      if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_RGB
        self.slc.clear_flag(lv.OBJ_FLAG_HIDDEN)
        self.sl_cbtn.set_style_bg_color(lv.color(lv.COLOR_GRAY/2), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.sl_cbtn.set_style_border_side(lv.BORDER_SIDE_TOP|lv.BORDER_SIDE_LEFT|lv.BORDER_SIDE_RIGHT,0)
        self.sl_cbtn.set_height(37)
        self.slc_colp.set_hsv(0xffff0000 | self.v_hue)
        self.slc_bri.set_value(self.v_cbrightness)
        self.slc_sat.set_value(self.v_saturation)
        self.slc_brilab.set_text(string.format("%3d%%",self.v_cbrightness))
        self.slc_satlab.set_text(string.format("%3d%%",self.v_saturation))
      end
      if self.devtype==self.DEV_DEFAULT || self.devtype==self.DEV_WHITE  
        self.slw.add_flag(lv.OBJ_FLAG_HIDDEN)
        self.sl_wbtn.set_style_bg_color(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.sl_wbtn.set_style_border_side(lv.BORDER_SIDE_TOP|lv.BORDER_SIDE_LEFT|lv.BORDER_SIDE_RIGHT|lv.BORDER_SIDE_BOTTOM,0)
        self.sl_wbtn.set_height(32)
      end
    end
  end

  def close_clicked()
    self.sl.del()
    self.sl=nil
  end

  def wbtn_clicked()
    self.v_mode=0 # white mode
    for t: self.topics
      # print("topic: ",t)
      mqtt.publish(t+'/mode_command','white')
    end
    self.show_sl()
  end

  def cbtn_clicked()
    self.v_mode=1 # color mode
    for t: self.topics
      mqtt.publish(t+'/mode_command','colour')
    end
    self.show_sl()
  end

  def slw_bri_cb()
    self.v_brightness=self.slw_bri.get_value()
    self.show_sl()
  end

  def slw_bri_r_cb()
    for t: self.topics
      mqtt.publish(t+'/white_brightness_command',string.format("%d",self.v_brightness))
    end
  end

  def slw_temp_cb()
    self.v_ctemp=self.slw_temp.get_value()
    self.show_sl()
  end

  def slw_temp_r_cb()
    for t: self.topics
      mqtt.publish(t+'/color_temp_command',string.format("%d",self.v_ctemp))
    end
  end

  def slc_cb()
    self.v_hue=self.slc_colp.get_hsv()& 0xffff
    self.v_cbrightness=self.slc_bri.get_value()
    self.v_saturation=self.slc_sat.get_value()
    self.show_sl()
  end

  def slc_r_cb()
    for t: self.topics
      # print("topic: ",t)
      mqtt.publish(t+'/hsb_command',string.format("%d,%d,%d",self.v_hue,self.v_saturation,self.v_cbrightness))
    end
  end

  #def before_del()
  # tasmota.remove_driver(self)
  #end

  def show()
    var bg=0
    var text=0xffffff # default black
    var br="" # brightness label
    if self.v_state==1 # light is on

    # calculate background, text color and brightness
      if self.v_mode==1 # light is in color mode
        var i=(self.v_hue+30)/60
        bg=(i>2 ? 0xc0 : 20)+((i+5)%6<3 ? 0xc000:0x2000)+((i+1)%6<3?0xc00000:0x200000)
        br=string.format("%3d%%",self.v_cbrightness)
      else # white mode
        text=0 # black text color
        if (self.v_ctemp>250 && self.v_ctemp<350) # just white
          bg=0xffffff
        else 
          if  (self.v_ctemp<=250) # more blue
            bg=0xC0C0FF
          else # more red
            bg=0xffC0C0
          end 
        end
        br=string.format("%3d%%",self.v_brightness)
      end
    elif self.v_state==2
      br="offline"
    end
    self.set_style_bg_color(lv.color(bg), lv.PART_MAIN | lv.STATE_DEFAULT)
    self.set_style_text_color(lv.color(text), lv.PART_MAIN | lv.STATE_DEFAULT)
    self.br_label.set_text(br)

    # lv.disp().trig_activity()
  end

end

return lv_tuya