use framework "Foundation"
use framework "AppKit"
use scripting additions

set W to 600
set H to 400
set outPath to (do shell script "pwd") & "/bg.png"

set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(W, H))
img's lockFocus()

-- 漸層背景（深色）
set c1 to current application's NSColor's colorWithCalibratedRed:(0.12) green:(0.12) blue:(0.16) alpha:(1.0)
set c2 to current application's NSColor's colorWithCalibratedRed:(0.18) green:(0.17) blue:(0.24) alpha:(1.0)
set grad to current application's NSGradient's alloc()'s initWithStartingColor:c1 endingColor:c2
grad's drawInRect:(current application's NSMakeRect(0, 0, W, H)) angle:90

-- 標題
set titleColor to current application's NSColor's whiteColor()
set titleFont to current application's NSFont's boldSystemFontOfSize:30
set tAttrs to current application's NSDictionary's dictionaryWithObjects:{titleFont, titleColor} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
set tStr to current application's NSString's stringWithString:"MapleStory 登入啟動器"
set tSize to tStr's sizeWithAttributes:tAttrs
set tx to (W - (width of tSize)) / 2
tStr's drawAtPoint:(current application's NSMakePoint(tx, 338)) withAttributes:tAttrs

-- 副標
set subColor to current application's NSColor's colorWithCalibratedRed:(0.7) green:(0.7) blue:(0.78) alpha:(1.0)
set subFont to current application's NSFont's systemFontOfSize:14
set sAttrs to current application's NSDictionary's dictionaryWithObjects:{subFont, subColor} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
set sStr to current application's NSString's stringWithString:"把左邊的程式拖到右邊的「應用程式」資料夾即可安裝"
set sSize to sStr's sizeWithAttributes:sAttrs
set sx to (W - (width of sSize)) / 2
sStr's drawAtPoint:(current application's NSMakePoint(sx, 308)) withAttributes:sAttrs

-- 中間箭頭 (從 app 指向 Applications)，圖示中心約在 image y=210
set arrowColor to current application's NSColor's colorWithCalibratedRed:(0.55) green:(0.55) blue:(0.65) alpha:(1.0)
arrowColor's setStroke()
arrowColor's setFill()
set p to current application's NSBezierPath's bezierPath()
p's setLineWidth:6
p's setLineCapStyle:(current application's NSLineCapStyleRound)
p's moveToPoint:(current application's NSMakePoint(258, 210))
p's lineToPoint:(current application's NSMakePoint(338, 210))
p's stroke()
-- 箭頭三角
set head to current application's NSBezierPath's bezierPath()
head's moveToPoint:(current application's NSMakePoint(356, 210))
head's lineToPoint:(current application's NSMakePoint(334, 222))
head's lineToPoint:(current application's NSMakePoint(334, 198))
head's closePath()
head's fill()

-- 底部小字
set tipColor to current application's NSColor's colorWithCalibratedRed:(0.5) green:(0.5) blue:(0.58) alpha:(1.0)
set tipFont to current application's NSFont's systemFontOfSize:12
set tipAttrs to current application's NSDictionary's dictionaryWithObjects:{tipFont, tipColor} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
set tipStr to current application's NSString's stringWithString:"第一次開啟請在程式上按右鍵 →「打開」。詳見「安裝說明.txt」"
set tipSize to tipStr's sizeWithAttributes:tipAttrs
set tipx to (W - (width of tipSize)) / 2
tipStr's drawAtPoint:(current application's NSMakePoint(tipx, 40)) withAttributes:tipAttrs

img's unlockFocus()

-- 存成 PNG
set tiff to img's TIFFRepresentation()
set rep to current application's NSBitmapImageRep's imageRepWithData:tiff
set pngData to rep's representationUsingType:(current application's NSBitmapImageFileTypePNG) |properties|:(current application's NSDictionary's dictionary())
pngData's writeToFile:outPath atomically:true
return outPath
