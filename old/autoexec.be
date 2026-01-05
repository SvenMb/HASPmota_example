import haspmota
import string
import lv_tuya

def add
  (haspobj,topic,devtype)
  haspobj.get_obj().add(topic)
  if devtype != nil
    haspobj.get_obj().set_devtype(devtype)
  end  
end

haspmota.start()

def DisplayON() end

def ObjOFF()
  tasmota.add_rule("hasp", DisplayON)
end

def DisplayOFF()
  tasmota.set_power(1,false)
  tasmota.set_power(2,false)
  # global.p3.show()
  tasmota.set_timer(500,ObjOFF)
  tasmota.remove_timer("timerDisplayChack")
end

def ObjON()
  tasmota.remove_rule("hasp")
  global.p1.show()
end

def DisplayAktiv()
  var inactive_time = lv.disp().get_inactive_time()
  if inactive_time > 60000
    DisplayOFF()
  else
    tasmota.set_timer(1000, DisplayAktiv, "timerDisplayChack")
  end
end

def DisplayON()
  tasmota.set_power(1,true)
  tasmota.set_power(2,true)
  tasmota.set_timer(500, ObjON)
  tasmota.set_timer(1000, DisplayAktiv)
end

DisplayON()

global.p3b11.get_obj().set_tasmota_logo()
global.p3b11.get_obj().set_style_img_recolor_opa(255, lv.PART_MAIN | lv.STATE_DEFAULT)
global.p3b11.get_obj().set_style_img_recolor(lv.color(lv.COLOR_WHITE), lv.PART_MAIN | lv.STATE_DEFAULT)
