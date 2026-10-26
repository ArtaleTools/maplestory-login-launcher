use framework "Foundation"
use framework "AppKit"
use scripting additions

property accountData : {} -- {lbl, eml} 記錄清單
property theApp : missing value
property theWin : missing value
property setupWin : missing value
property theTable : missing value
property didLogin : false
property chosenEmail : ""
property gIdx : ""
property gLast : ""
property gClear : ""
property gSetup : ""
property gGame : "/Library/Application Support/Nexon/MapleStory Worlds/MapleStory Worlds.app"

on run
	set h to POSIX path of (path to home folder)
	set gIdx to h & "Library/Application Support/MapleLauncher/accounts.txt"
	set gLast to h & "Library/Application Support/MapleLauncher/last_account.txt"
	set gClear to h & "Library/Application Support/MapleLauncher/clear_login.sh"
	set gSetup to h & "Library/Application Support/MapleLauncher/setup_done"
	do shell script "mkdir -p " & quoted form of (h & "Library/Application Support/MapleLauncher")
	my loadAccounts()
	set theApp to current application's NSApplication's sharedApplication()
	theApp's activateIgnoringOtherApps:true
	my firstRunSetup()
	my buildWindow()
	theApp's runModalForWindow:theWin
	theWin's orderOut:me
	if didLogin then my doLogin()
end run

-- ===== 帳號資料 =====
on loadAccounts()
	set accountData to {}
	set raw to ""
	try
		set raw to do shell script "cat " & quoted form of gIdx & " 2>/dev/null"
	end try
	if raw is not "" then
		set AppleScript's text item delimiters to return
		set ls to text items of raw
		set AppleScript's text item delimiters to ""
		repeat with ln in ls
			set lnS to ln as text
			if lnS is not "" then
				set AppleScript's text item delimiters to "|"
				set ps to text items of lnS
				set AppleScript's text item delimiters to ""
				if (count of ps) > 1 then
					set end of accountData to {lbl:(item 1 of ps), eml:(last item of ps)}
				else
					set end of accountData to {lbl:"", eml:lnS}
				end if
			end if
		end repeat
	end if
end loadAccounts

on saveAccounts()
	set outLines to {}
	repeat with rec in accountData
		if (lbl of rec) is "" then
			set end of outLines to (eml of rec)
		else
			set end of outLines to ((lbl of rec) & "|" & (eml of rec))
		end if
	end repeat
	set AppleScript's text item delimiters to linefeed
	set cnt to outLines as text
	set AppleScript's text item delimiters to ""
	do shell script "printf %s " & quoted form of cnt & " > " & quoted form of gIdx
end saveAccounts

-- ===== 瀏覽器偵測 =====
-- 回傳預設瀏覽器的 {AppleScript名稱, 引擎}；引擎 = chromium / safari / unsupported
on detectBrowser()
	set bid to ""
	try
		set ws to current application's NSWorkspace's sharedWorkspace()
		set u to current application's NSURL's URLWithString:"https://www.nexon.com"
		set appURL to ws's URLForApplicationToOpenURL:u
		set b to current application's NSBundle's bundleWithURL:appURL
		set bid to (b's bundleIdentifier()) as text
	end try
	return my browserInfo(bid)
end detectBrowser

on browserInfo(bid)
	if bid is "com.google.Chrome" then return {"Google Chrome", "chromium"}
	if bid is "com.google.Chrome.beta" then return {"Google Chrome Beta", "chromium"}
	if bid is "com.microsoft.edgemac" then return {"Microsoft Edge", "chromium"}
	if bid is "com.brave.Browser" then return {"Brave Browser", "chromium"}
	if bid is "com.vivaldi.Vivaldi" then return {"Vivaldi", "chromium"}
	if bid is "com.operasoftware.Opera" then return {"Opera", "chromium"}
	if bid is "com.apple.Safari" then return {"Safari", "safari"}
	if bid is "org.mozilla.firefox" then return {"Firefox", "unsupported"}
	return {"", "unsupported"}
end browserInfo

-- ===== 首次設定引導 (圖文 + 紅圈) =====
on firstRunSetup()
	set done to false
	try
		do shell script "test -f " & quoted form of gSetup
		set done to true
	end try
	if done then return
	set bi to my detectBrowser()
	set bName to item 1 of bi
	set engine to item 2 of bi
	set imgName to ""
	if engine is "chromium" then
		set imgName to "guide_chromium.png"
	else if engine is "safari" then
		set imgName to "guide_safari.png"
	end if
	set shown to false
	if imgName is not "" then
		set resPath to ""
		try
			set resPath to (current application's NSBundle's mainBundle()'s resourcePath()) as text
		end try
		if resPath is not "" then
			set img to (current application's NSImage's alloc()'s initWithContentsOfFile:(resPath & "/" & imgName))
			if img is not missing value then
				my showSetupWindow(img)
				set shown to true
			end if
		end if
	end if
	if not shown then
		if engine is "chromium" then
			set msg to "首次使用請在「" & bName & "」選單列開啟：
檢視 (View) → 開發人員 (Developer) → 允許 Apple 事件的 JavaScript

之後第一次登入若跳出『允許控制』視窗，請按「好／允許」。"
		else if engine is "safari" then
			set msg to "首次使用請在 Safari 開啟：
1. Safari → 設定 → 進階 → 勾『在選單列顯示開發選單』
2. 開發 → 允許來自 Apple 事件的 JavaScript

之後第一次登入若跳出『允許控制』視窗，請按「好／允許」。"
		else
			set msg to "偵測到預設瀏覽器為「" & bName & "」。
自動登入支援 Chrome / Edge / Brave / Vivaldi / Opera / Safari；其他瀏覽器會改用『複製密碼、手動貼上』模式。
建議把預設瀏覽器設為上述其中一種。"
		end if
		try
			display dialog msg buttons {"知道了"} default button 1 with title "MapleStory 登入啟動器 — 首次設定"
		end try
	end if
	do shell script "touch " & quoted form of gSetup
end firstRunSetup

on showSetupWindow(img)
	set setupWin to current application's NSWindow's alloc()'s initWithContentRect:(current application's NSMakeRect(0, 0, 660, 660)) styleMask:3 backing:2 defer:false
	setupWin's setTitle:"MapleStory 登入啟動器 — 首次設定"
	setupWin's |center|()
	set cv to setupWin's contentView()
	set iv to current application's NSImageView's alloc()'s initWithFrame:(current application's NSMakeRect(20, 78, 620, 565))
	iv's setImage:img
	iv's setImageScaling:3
	cv's addSubview:iv
	set noteLbl to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(24, 30, 430, 20))
	noteLbl's setStringValue:"照著紅圈順序操作，完成後按「知道了」"
	noteLbl's setBezeled:false
	noteLbl's setDrawsBackground:false
	noteLbl's setEditable:false
	noteLbl's setSelectable:false
	cv's addSubview:noteLbl
	set okb to current application's NSButton's alloc()'s initWithFrame:(current application's NSMakeRect(550, 24, 90, 32))
	okb's setTitle:"知道了"
	okb's setBezelStyle:1
	okb's setKeyEquivalent:(return)
	okb's setTarget:me
	okb's setAction:"setupDoneBtn:"
	cv's addSubview:okb
	theApp's runModalForWindow:setupWin
	setupWin's orderOut:me
end showSetupWindow

on setupDoneBtn:sender
	theApp's stopModal()
end setupDoneBtn:

-- ===== 視窗 UI =====
on buildWindow()
	set theWin to current application's NSWindow's alloc()'s initWithContentRect:(current application's NSMakeRect(0, 0, 580, 340)) styleMask:3 backing:2 defer:false
	theWin's setTitle:"MapleStory 登入啟動器"
	theWin's |center|()
	set cv to theWin's contentView()
	set lab to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(20, 305, 540, 20))
	lab's setStringValue:"選帳號按「登入」；點「備註」欄可直接輸入名稱"
	lab's setBezeled:false
	lab's setDrawsBackground:false
	lab's setEditable:false
	lab's setSelectable:false
	cv's addSubview:lab
	set sv to current application's NSScrollView's alloc()'s initWithFrame:(current application's NSMakeRect(20, 70, 540, 230))
	sv's setHasVerticalScroller:true
	sv's setBorderType:(current application's NSBezelBorder)
	set theTable to current application's NSTableView's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 540, 230))
	set colL to (current application's NSTableColumn's alloc()'s initWithIdentifier:"lbl")
	colL's setWidth:95
	colL's setMinWidth:60
	(colL's headerCell())'s setStringValue:"備註"
	(colL's headerCell())'s setAlignment:(current application's NSTextAlignmentCenter)
	theTable's addTableColumn:colL
	set colE to (current application's NSTableColumn's alloc()'s initWithIdentifier:"eml")
	colE's setWidth:380
	colE's setMinWidth:200
	(colE's headerCell())'s setStringValue:"帳號 (Email)"
	(colE's headerCell())'s setAlignment:(current application's NSTextAlignmentCenter)
	theTable's addTableColumn:colE
	theTable's setRowHeight:30
	theTable's setColumnAutoresizingStyle:4
	theTable's setDataSource:me
	theTable's setDelegate:me
	sv's setDocumentView:theTable
	theTable's sizeLastColumnToFit()
	cv's addSubview:sv
	set b1 to current application's NSButton's alloc()'s initWithFrame:(current application's NSMakeRect(20, 20, 100, 32))
	b1's setTitle:"登入"
	b1's setBezelStyle:1
	b1's setKeyEquivalent:(return)
	b1's setTarget:me
	b1's setAction:"doLoginBtn:"
	cv's addSubview:b1
	set b2 to current application's NSButton's alloc()'s initWithFrame:(current application's NSMakeRect(130, 20, 110, 32))
	b2's setTitle:"新增帳號"
	b2's setBezelStyle:1
	b2's setTarget:me
	b2's setAction:"addAcctBtn:"
	cv's addSubview:b2
	set b3 to current application's NSButton's alloc()'s initWithFrame:(current application's NSMakeRect(250, 20, 90, 32))
	b3's setTitle:"刪除"
	b3's setBezelStyle:1
	b3's setTarget:me
	b3's setAction:"delAcctBtn:"
	cv's addSubview:b3
	set b4 to current application's NSButton's alloc()'s initWithFrame:(current application's NSMakeRect(470, 20, 90, 32))
	b4's setTitle:"關閉"
	b4's setBezelStyle:1
	b4's setKeyEquivalent:(character id 27)
	b4's setTarget:me
	b4's setAction:"closeBtn:"
	cv's addSubview:b4
	theTable's reloadData()
end buildWindow

on numberOfRowsInTableView:tv
	return (count of accountData)
end numberOfRowsInTableView:

on tableView:tv viewForTableColumn:col row:r
	set rec to item (r + 1) of accountData
	set cid to (col's identifier()) as text
	set w to (col's width())
	set box to current application's NSView's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, w, 30))
	box's setAutoresizesSubviews:true
	set tf to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(0, 5, w, 20))
	tf's setAutoresizingMask:2
	tf's setAlignment:(current application's NSTextAlignmentCenter)
	tf's setBordered:false
	tf's setDrawsBackground:false
	tf's setFont:(current application's NSFont's systemFontOfSize:13)
	if cid is "lbl" then
		tf's setStringValue:(lbl of rec)
		tf's setPlaceholderString:"待填入名稱"
		tf's setEditable:true
		tf's setSelectable:true
		tf's setDelegate:me
		tf's setTag:(r + 1)
	else
		tf's setStringValue:(eml of rec)
		tf's setEditable:false
		tf's setSelectable:false
	end if
	box's addSubview:tf
	return box
end tableView:viewForTableColumn:row:

on controlTextDidEndEditing:aNotification
	set tf to (aNotification's object())
	set idx to (tf's tag()) as integer
	if idx < 1 then return
	set nl to ""
	try
		set nl to (tf's stringValue()) as text
	end try
	my setLabelAt(idx, nl)
	my saveAccounts()
end controlTextDidEndEditing:

on setLabelAt(idx, newLbl)
	set newData to {}
	repeat with i from 1 to count of accountData
		set rec to item i of accountData
		if i is idx then
			set end of newData to {lbl:newLbl, eml:(eml of rec)}
		else
			set end of newData to rec
		end if
	end repeat
	set accountData to newData
end setLabelAt

-- ===== 按鈕 =====
on doLoginBtn:sender
	set r to (theTable's selectedRow()) as integer
	if r < 0 then return
	set chosenEmail to (eml of (item (r + 1) of accountData))
	set didLogin to true
	theApp's stopModal()
end doLoginBtn:

on addAcctBtn:sender
	try
		set em to text returned of (display dialog "輸入 Nexon 帳號 (Email)：" default answer "" with title "新增帳號")
		set lbl2 to text returned of (display dialog "輸入備註名稱 (可留空)：" default answer "" with title "新增帳號")
		set pwd to text returned of (display dialog "輸入該帳號密碼：" default answer "" with hidden answer with title "新增帳號")
	on error
		return
	end try
	if em is "" or pwd is "" then return
	do shell script "security add-generic-password -U -A -s 'MapleWorldsLogin' -a " & quoted form of em & " -w " & quoted form of pwd
	set end of accountData to {lbl:lbl2, eml:em}
	my saveAccounts()
	theTable's reloadData()
end addAcctBtn:

on delAcctBtn:sender
	set r to (theTable's selectedRow()) as integer
	if r < 0 then return
	set rec to item (r + 1) of accountData
	try
		display dialog "確定刪除帳號「" & (eml of rec) & "」？(只移除清單，鑰匙圈密碼保留)" buttons {"取消", "刪除"} default button 1
	on error
		return
	end try
	set newData to {}
	repeat with i from 1 to count of accountData
		if i is not (r + 1) then set end of newData to (item i of accountData)
	end repeat
	set accountData to newData
	my saveAccounts()
	theTable's reloadData()
end delAcctBtn:

on closeBtn:sender
	theApp's stopModal()
end closeBtn:

-- ===== 登入主流程 =====
on buildJS(accB64, pwB64)
	return "(function(){if(window.__ml)return 'dup';window.__ml=1;var E=atob('" & accB64 & "'),P=atob('" & pwB64 & "');function S(el,v){var d=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value');d.set.call(el,v);el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));}function uc(){var cs=document.querySelectorAll('input[type=checkbox]');for(var i=0;i<cs.length;i++){if(cs[i].checked)cs[i].click();}}function btn(ws){var bs=document.querySelectorAll('button,input[type=submit]');for(var i=0;i<bs.length;i++){var t=(bs[i].textContent||bs[i].value||'').trim();for(var j=0;j<ws.length;j++){if(t===ws[j])return bs[i];}}return null;}var step='e';function tick(){try{if(step==='e'){var e=document.querySelector('input[type=email],input[type=text]');if(e){if(e.value!==E){S(e,E);uc();return;}var b=btn(['繼續','Continue','下一步','Next']);if(b&&!b.disabled){uc();b.click();step='p';}}}else if(step==='p'){var p=document.querySelector('input[type=password]');if(p){if(p.value.length!==P.length){S(p,P);uc();return;}var b=btn(['登入','Login','Sign in']);if(b&&!b.disabled){uc();b.click();step='d';cleanup();}}}}catch(x){}}function cleanup(){try{mo.disconnect();}catch(x){}try{clearInterval(iv);}catch(x){}}var mo=new MutationObserver(tick);try{mo.observe(document.documentElement,{childList:true,subtree:true,attributes:true});}catch(x){}var iv=setInterval(tick,90);tick();return 'injected';})();"
end buildJS

on doLogin()
	-- 遊戲是否安裝
	set gameExists to false
	try
		do shell script "test -d " & quoted form of gGame
		set gameExists to true
	end try
	if not gameExists then
		try
			display dialog "找不到 MapleStory Worlds 遊戲，請先安裝。" buttons {"好"} default button 1 with icon caution
		end try
		return
	end if
	set theAcc to chosenEmail
	set thePw to ""
	try
		set thePw to do shell script "security find-generic-password -s 'MapleWorldsLogin' -a " & quoted form of theAcc & " -w 2>/dev/null"
	end try
	if thePw is "" then
		try
			display dialog "讀不到此帳號的密碼。" buttons {"好"} default button 1 with icon caution
		end try
		return
	end if
	set accB64 to do shell script "printf %s " & quoted form of theAcc & " | base64 | tr -d '\\n'"
	set pwB64 to do shell script "printf %s " & quoted form of thePw & " | base64 | tr -d '\\n'"
	set lastAcc to ""
	try
		set lastAcc to do shell script "cat " & quoted form of gLast & " 2>/dev/null"
	end try
	set isSwitch to (theAcc is not lastAcc)
	-- 同帳號且遊戲已開 → 直接切回
	if not isSwitch then
		set gameRunning to false
		try
			do shell script "pgrep -f 'MapleStory Worlds.app' >/dev/null 2>&1"
			set gameRunning to true
		end try
		if gameRunning then
			try
				tell application "MapleStory Worlds" to activate
			end try
			do shell script "open " & quoted form of gGame
			return
		end if
	end if
	-- 偵測瀏覽器
	set bi to my detectBrowser()
	set bName to item 1 of bi
	set engine to item 2 of bi
	-- 換帳號 → 清遊戲權杖 (+ Chromium 清 cookie)
	if isSwitch then
		try
			tell application "MapleStory Worlds" to quit
		end try
		delay 1.2
		try
			do shell script "pkill -9 -f 'MapleStory Worlds.app' 2>/dev/null; defaults delete com.nexon.mod.inhouse _access_token 2>/dev/null; killall cfprefsd 2>/dev/null; true"
		end try
		if engine is "chromium" then
			try
				do shell script "bash " & quoted form of gClear & " " & quoted form of bName & " >/dev/null 2>&1 &"
			end try
		end if
		delay 0.2
	end if
	do shell script "open " & quoted form of gGame
	-- 依引擎跑登入
	if engine is "chromium" then
		my loginChromium(bName, accB64, pwB64, isSwitch)
	else if engine is "safari" then
		my loginSafari(accB64, pwB64, isSwitch)
	else
		my loginFallback(theAcc, thePw)
	end if
	try
		do shell script "echo " & quoted form of theAcc & " > " & quoted form of gLast
	end try
	try
		do shell script "open " & quoted form of gGame
	end try
end doLogin

-- Chromium 家族 (Chrome/Edge/Brave/Vivaldi/Opera) 共用 Chrome 字典
on loginChromium(bName, accB64, pwB64, isSwitch)
	set jsLogin to my buildJS(accB64, pwB64)
	set loginFound to false
	set autoDone to false
	set myTab to missing value
	set maxN to 60
	if isSwitch then set maxN to 240
	using terms from application "Google Chrome"
		repeat maxN times
			delay 0.2
			try
				tell application bName
					repeat with w in windows
						set ti to 0
						repeat with t in tabs of w
							set ti to ti + 1
							set u to URL of t
							if (u contains "login=success") or (u contains "/close") then
								close t
								set autoDone to true
								exit repeat
							else if (u contains "nexon") and ((u contains "/login") or (u contains "signin") or (u contains "/account")) then
								set he to "0"
								try
									set he to (execute t javascript "document.querySelector('input[type=email],input[type=text]')?'1':'0'")
								end try
								if (he as text) is "1" then
									set active tab index of w to ti
									set index of w to 1
									set loginFound to true
									set myTab to t
									exit repeat
								end if
							end if
						end repeat
						if autoDone or loginFound then exit repeat
					end repeat
				end tell
			end try
			if autoDone or loginFound then exit repeat
		end repeat
		if loginFound and (not autoDone) then
			try
				tell application bName to activate
			end try
			try
				tell application bName to execute myTab javascript jsLogin
			end try
			repeat 120 times
				delay 0.2
				set didClose to false
				try
					tell application bName
						repeat with w in windows
							repeat with t in tabs of w
								set u to URL of t
								if (u contains "login=success") or (u contains "/close") then
									close t
									set didClose to true
									exit repeat
								end if
							end repeat
							if didClose then exit repeat
						end repeat
					end tell
				end try
				if didClose then exit repeat
			end repeat
		end if
	end using terms from
end loginChromium

-- Safari (語法不同：do JavaScript ... in tab)
on loginSafari(accB64, pwB64, isSwitch)
	set jsLogin to my buildJS(accB64, pwB64)
	set loginFound to false
	set autoDone to false
	set myTab to missing value
	set myWin to missing value
	set maxN to 60
	if isSwitch then set maxN to 240
	using terms from application "Safari"
		repeat maxN times
			delay 0.2
			try
				tell application "Safari"
					repeat with w in windows
						repeat with t in tabs of w
							set u to ""
							try
								set u to URL of t
							end try
							if u is missing value then set u to ""
							if (u contains "login=success") or (u contains "/close") then
								close t
								set autoDone to true
								exit repeat
							else if (u contains "nexon") and ((u contains "/login") or (u contains "signin") or (u contains "/account")) then
								set he to "0"
								try
									set he to (do JavaScript "document.querySelector('input[type=email],input[type=text]')?'1':'0'" in t)
								end try
								if (he as text) is "1" then
									set myTab to t
									set myWin to w
									set loginFound to true
									exit repeat
								end if
							end if
						end repeat
						if autoDone or loginFound then exit repeat
					end repeat
				end tell
			end try
			if autoDone or loginFound then exit repeat
		end repeat
		if loginFound and (not autoDone) then
			try
				tell application "Safari"
					set current tab of myWin to myTab
					set index of myWin to 1
					activate
				end tell
			end try
			try
				tell application "Safari" to do JavaScript jsLogin in myTab
			end try
			repeat 120 times
				delay 0.2
				set didClose to false
				try
					tell application "Safari"
						repeat with w in windows
							repeat with t in tabs of w
								set u to ""
								try
									set u to URL of t
								end try
								if u is missing value then set u to ""
								if (u contains "login=success") or (u contains "/close") then
									close t
									set didClose to true
									exit repeat
								end if
							end repeat
							if didClose then exit repeat
						end repeat
					end tell
				end try
				if didClose then exit repeat
			end repeat
		end if
	end using terms from
end loginSafari

-- 不支援自動填入的瀏覽器：複製密碼、提示手動貼上
on loginFallback(theAcc, thePw)
	try
		do shell script "printf %s " & quoted form of thePw & " | pbcopy"
	end try
	try
		display notification "密碼已複製到剪貼簿，請在登入頁手動貼上。帳號：" & theAcc with title "MapleStory 登入啟動器"
	end try
end loginFallback
