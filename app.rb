require 'rubygems'
require 'selenium-webdriver'
require 'rmagick'


CHROME_DRIVER = File.join(File.absolute_path('./lib'), 'chromedriver')


class ChromeWorker


  attr_accessor :url


  def initialize(url)
    Selenium::WebDriver::Chrome.driver_path = CHROME_DRIVER
    @driver = Selenium::WebDriver.for :chrome
    @url = url
  end


  def process
    @driver.get @url
    sleep 2
    @driver.execute_script("document.getElementById('carbonads').style.display='none';")
    maximalize_window
    scroll_and_shot
  ensure
    clear_tmp_images
    close_browser
  end


  def body_height
    @driver.execute_script("return document.getElementsByTagName('body')[0].scrollHeight;")
  end


  def screen_height
    @driver.execute_script("return window.innerHeight;")
  end


  def maximalize_window
    @driver.manage.window.maximize
  end


  def scroll_and_shot
    screenshot('tmp-0')
    images_list = ["tmp-0.png"]
    scrolls = calculate_scrolls(body_height)
    height = screen_height
    (1..scrolls).each do |i|
      scroll(0, height)
      sleep 0.5
      screenshot("tmp-#{i}")
      images_list << "tmp-#{i}.png"
      height += screen_height
    end
    crop_last_image(images_list, calculate_left_pixels)
    join_images(images_list)
  end


  def join_images(images)
    image_list = Magick::ImageList.new(*images)
    image_list.append(true).write("page_screenshot.png")
  end


  def scroll(x, y)
    @driver.execute_script("window.scrollTo(#{x}, #{y})")
  end


  def calculate_scrolls(body_height)
    body_height.to_i/screen_height
  end


  def calculate_left_pixels
    screen_height.to_i - (body_height.to_i - (screen_height.to_i * calculate_scrolls(body_height)))
  end


  def screenshot(file_name)
    @driver.save_screenshot("#{file_name}.png")
  end


  def crop_last_image(images, pixels)
    image = Magick::ImageList.new(images.last)
    image.crop!(0, pixels, 0, 0)
    image.write(images.last)
  end


  def clear_tmp_images
    FileUtils.rm Dir.glob('tmp-*')
  end


  def close_browser
    @driver.close
  end


end

worker = ChromeWorker.new('http://ruby-doc.org/core-2.3.0/Enumerable.html')
worker.process

