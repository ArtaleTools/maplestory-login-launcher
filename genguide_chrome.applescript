use framework "Foundation"
use framework "AppKit"
use scripting additions

-- 以真實 Chrome 選單截圖合成教學圖（紅圈標步驟）
property SW : 578 -- 截圖寬
property SH : 542 -- 截圖高
property titleH : 48

on run
	set base to (do shell script "pwd") & "/"
	set shot to (current application's NSImage's alloc()'s initWithContentsOfFile:(base & "chrome_menu.png"))
	set W to SW
	set H to SH + titleH
	set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(W, H))
	img's lockFocus()
	-- 標題底
	(current application's NSColor's colorWithCalibratedRed:(0.12) green:(0.12) blue:(0.16) alpha:(1.0))'s setFill()
	(current application's NSBezierPath's fillRect:(current application's NSMakeRect(0, SH, W, titleH)))
	-- 畫截圖在下方
	shot's drawInRect:(current application's NSMakeRect(0, 0, SW, SH)) fromRect:(current application's NSZeroRect) operation:(current application's NSCompositingOperationSourceOver) fraction:1.0
	-- 標題文字
	set tFont to current application's NSFont's boldSystemFontOfSize:19
	set tAttrs to current application's NSDictionary's dictionaryWithObjects:{tFont, (current application's NSColor's whiteColor())} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
	set tStr to current application's NSString's stringWithString:"首次設定：依紅圈 ① ② ③ 開啟「允許 Apple 事件的 JavaScript」"
	set tsz to tStr's sizeWithAttributes:tAttrs
	tStr's drawAtPoint:(current application's NSMakePoint((W - (width of tsz)) / 2, SH + 14)) withAttributes:tAttrs
	-- 三個紅圈 (以截圖左上原點座標給，sy 轉成畫布座標)
	my redRect(53, 15, 47, 12)
	my redRect(154, 429, 148, 13)
	my redRect(436, 521, 138, 16)
	-- 三個編號圈
	my numDot(110, 14, 1)
	my numDot(312, 429, 2)
	my numDot(555, 521, 3)
	img's unlockFocus()
	-- 輸出
	set tiff to img's TIFFRepresentation()
	set rep to current application's NSBitmapImageRep's imageRepWithData:tiff
	set pngData to rep's representationUsingType:(current application's NSBitmapImageFileTypePNG) |properties|:(current application's NSDictionary's dictionary())
	pngData's writeToFile:(base & "guide_chromium.png") atomically:true
	return "done"
end run

on sy(py)
	return (SH - py)
end sy

on redRect(cxp, cyp, rx, ry)
	set cy to my sy(cyp)
	set rr to current application's NSMakeRect(cxp - rx, cy - ry, rx * 2, ry * 2)
	set rad to ry
	if rad > 12 then set rad to 12
	set p to current application's NSBezierPath's bezierPathWithRoundedRect:rr xRadius:rad yRadius:rad
	(current application's NSColor's colorWithCalibratedRed:(0.98) green:(0.2) blue:(0.2) alpha:(1.0))'s setStroke()
	p's setLineWidth:4
	p's stroke()
end redRect

on numDot(cxp, cyp, num)
	set cy to my sy(cyp)
	set rad to 10
	set r to current application's NSMakeRect(cxp - rad, cy - rad, rad * 2, rad * 2)
	set p to current application's NSBezierPath's bezierPathWithOvalInRect:r
	(current application's NSColor's colorWithCalibratedRed:(0.98) green:(0.2) blue:(0.2) alpha:(1.0))'s setFill()
	p's fill()
	(current application's NSColor's whiteColor())'s setStroke()
	p's setLineWidth:2
	p's stroke()
	set nFont to current application's NSFont's boldSystemFontOfSize:14
	set nAttrs to current application's NSDictionary's dictionaryWithObjects:{nFont, (current application's NSColor's whiteColor())} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
	set ns to current application's NSString's stringWithString:(num as text)
	set nsz to ns's sizeWithAttributes:nAttrs
	ns's drawAtPoint:(current application's NSMakePoint(cxp - ((width of nsz) / 2), cy - ((height of nsz) / 2))) withAttributes:nAttrs
end numDot
