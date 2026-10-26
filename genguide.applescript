use framework "Foundation"
use framework "AppKit"
use scripting additions

property W : 560
property H : 440

on run
	set base to (do shell script "pwd") & "/"
	my drawGuide(base & "guide_chromium.png", "首次設定：開啟「允許 Apple 事件的 JavaScript」", ¬
		{"點選單列 → 檢視 (View)", "→ 開發人員 (Developer)", "→ 允許 Apple 事件的 JavaScript  ✓"}, 3)
	my drawGuide(base & "guide_safari.png", "首次設定（Safari）：開啟開發選單的 JavaScript", ¬
		{"Safari → 設定 → 進階", "勾「在選單列顯示開發選單」", "開發 → 允許來自 Apple 事件的 JavaScript  ✓"}, 3)
	return "done"
end run

on drawGuide(outPath, titleText, stepList, hiIndex)
	set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(W, H))
	img's lockFocus()
	-- 漸層背景
	set c1 to current application's NSColor's colorWithCalibratedRed:(0.12) green:(0.12) blue:(0.16) alpha:(1.0)
	set c2 to current application's NSColor's colorWithCalibratedRed:(0.18) green:(0.17) blue:(0.24) alpha:(1.0)
	set grad to current application's NSGradient's alloc()'s initWithStartingColor:c1 endingColor:c2
	grad's drawInRect:(current application's NSMakeRect(0, 0, W, H)) angle:90
	-- 標題
	set tFont to current application's NSFont's boldSystemFontOfSize:19
	set tCol to current application's NSColor's whiteColor()
	my drawCenteredText(titleText, tFont, tCol, 400)
	-- 三張步驟卡
	set ycs to {330, 235, 140}
	repeat with i from 1 to 3
		set yc to item i of ycs
		set isHi to (i is hiIndex)
		my drawCard(item i of stepList, i, yc, isHi)
		if i < 3 then my drawArrow(300, (yc - 28), 18)
	end repeat
	-- 底部提示
	set fFont to current application's NSFont's systemFontOfSize:12
	set fCol to current application's NSColor's colorWithCalibratedRed:(0.6) green:(0.6) blue:(0.68) alpha:(1.0)
	my drawCenteredText("依紅圈順序操作，完成後按「知道了」", fFont, fCol, 24)
	img's unlockFocus()
	-- 輸出 PNG
	set tiff to img's TIFFRepresentation()
	set rep to current application's NSBitmapImageRep's imageRepWithData:tiff
	set pngData to rep's representationUsingType:(current application's NSBitmapImageFileTypePNG) |properties|:(current application's NSDictionary's dictionary())
	pngData's writeToFile:outPath atomically:true
end drawGuide

on drawCard(txt, num, yc, isHi)
	set cx to 95
	set cw to 430
	set ch to 56
	set cy to (yc - (ch / 2))
	-- 卡片底
	set cardRect to current application's NSMakeRect(cx, cy, cw, ch)
	set cardPath to current application's NSBezierPath's bezierPathWithRoundedRect:cardRect xRadius:10 yRadius:10
	(current application's NSColor's colorWithCalibratedRed:(0.22) green:(0.22) blue:(0.28) alpha:(1.0))'s setFill()
	cardPath's fill()
	(current application's NSColor's colorWithCalibratedRed:(0.4) green:(0.4) blue:(0.48) alpha:(1.0))'s setStroke()
	cardPath's setLineWidth:1
	cardPath's stroke()
	-- 高亮卡：紅框
	if isHi then
		set hiRect to current application's NSMakeRect(cx - 4, cy - 4, cw + 8, ch + 8)
		set hiPath to current application's NSBezierPath's bezierPathWithRoundedRect:hiRect xRadius:12 yRadius:12
		(current application's NSColor's colorWithCalibratedRed:(0.95) green:(0.26) blue:(0.26) alpha:(1.0))'s setStroke()
		hiPath's setLineWidth:3
		hiPath's stroke()
	end if
	-- 卡片文字
	set tFont to current application's NSFont's systemFontOfSize:16
	set tCol to current application's NSColor's whiteColor()
	set tAttrs to current application's NSDictionary's dictionaryWithObjects:{tFont, tCol} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
	set s to current application's NSString's stringWithString:txt
	set ssz to s's sizeWithAttributes:tAttrs
	s's drawAtPoint:(current application's NSMakePoint(130, yc - ((height of ssz) / 2))) withAttributes:tAttrs
	-- 步驟紅圈 + 數字
	set r to 19
	set ncx to 55
	set circRect to current application's NSMakeRect(ncx - r, yc - r, r * 2, r * 2)
	set circPath to current application's NSBezierPath's bezierPathWithOvalInRect:circRect
	(current application's NSColor's colorWithCalibratedRed:(0.95) green:(0.26) blue:(0.26) alpha:(1.0))'s setFill()
	circPath's fill()
	set nFont to current application's NSFont's boldSystemFontOfSize:20
	set nCol to current application's NSColor's whiteColor()
	set nAttrs to current application's NSDictionary's dictionaryWithObjects:{nFont, nCol} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
	set ns to current application's NSString's stringWithString:(num as text)
	set nsz to ns's sizeWithAttributes:nAttrs
	ns's drawAtPoint:(current application's NSMakePoint(ncx - ((width of nsz) / 2), yc - ((height of nsz) / 2))) withAttributes:nAttrs
end drawCard

on drawArrow(cx, topY, len)
	set col to current application's NSColor's colorWithCalibratedRed:(0.55) green:(0.55) blue:(0.65) alpha:(1.0)
	col's setStroke()
	col's setFill()
	set p to current application's NSBezierPath's bezierPath()
	p's setLineWidth:4
	p's moveToPoint:(current application's NSMakePoint(cx, topY - 2))
	p's lineToPoint:(current application's NSMakePoint(cx, topY - len + 6))
	p's stroke()
	set head to current application's NSBezierPath's bezierPath()
	head's moveToPoint:(current application's NSMakePoint(cx, topY - len))
	head's lineToPoint:(current application's NSMakePoint(cx - 7, topY - len + 10))
	head's lineToPoint:(current application's NSMakePoint(cx + 7, topY - len + 10))
	head's closePath()
	head's fill()
end drawArrow

on drawCenteredText(txt, aFont, aCol, y)
	set attrs to current application's NSDictionary's dictionaryWithObjects:{aFont, aCol} forKeys:{(current application's NSFontAttributeName), (current application's NSForegroundColorAttributeName)}
	set s to current application's NSString's stringWithString:txt
	set ssz to s's sizeWithAttributes:attrs
	set x to (W - (width of ssz)) / 2
	s's drawAtPoint:(current application's NSMakePoint(x, y)) withAttributes:attrs
end drawCenteredText
