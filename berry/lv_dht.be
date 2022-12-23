# lv_dht class

import json

class lv_dht : lv.label
  var msg
  var delay

  def init(parent)
    super(self).init(parent)
    self.set_width(parent.get_width())
    self.set_pos(0, 0)

    # self.set_style_bg_color(lv.color(0x000000), lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_style_bg_opa(100, lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.move_background()
    # self.set_style_border_opa(255, lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_style_radius(0, lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_style_pad_all(2, lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_style_border_color(lv.color(0x0099EE), lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_style_border_width(1, lv.PART_MAIN | lv.STATE_DEFAULT)

    # self.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)
    # self.set_long_mode(lv.LABEL_LONG_CLIP)
    # var lg_font = lv.font_montserrat(14)
    # self.set_style_text_font(lg_font, lv.PART_MAIN | lv.STATE_DEFAULT)

    self.msg = ""
    self.set_text(self.msg)
    self.delay = 1

    self.add_event_cb(/->self.before_del(), lv.EVENT_DELETE, 0)   # register `before_del` to be called when object is deleted
    tasmota.add_driver(self)
  end

  def update()
    var sensors = json.load(tasmota.read_sensors())
    var temp = sensors['DHT11']['Temperature']
    var humi = sensors['DHT11']['Humidity']
    var ram = tasmota.memory().find('heap_free')
    if temp == nil
      temp="---"
    end
    if humi == nil
      humi="---"
    end
    if ram == nil
      ram='---'
    end
    var msg = '\xee\x94\x8f ' + str(temp) + " \xc2\xb0C\n\xee\x96\x8c " + str(humi) + " %\n\xEF\x84\x9C " + str(ram) +"kb"
    if msg != self.msg
      self.msg = msg
      self.set_text(self.msg)
    end
  end

  def every_second()
    self.delay -= 1
    if self.delay == 0
      self.update()
      self.delay = 1
    end
  end

  def before_del()
    tasmota.remove_driver(self)
  end
end

return lv_dht

#-
import lv_dht
var info = lv_dht(scr)
info.set_pos(0, stat_line.get_height())
info.set_size(hres - 80, 30)
tasmota.add_driver(info)
-#