##############################################
# LeapingJS - Engine Core
# Copyright (c) 2014,2015 Queue Sakura-Shiki
# Released under the MIT license
# 

# Page switching time
PAGE_DELAY = 60

# Polyfills for AnimationFrame API
nextFrame = 
# window.requestAnimationFrame || 
# window.mozRequestAnimationFrame || 
# window.msRequestAnimationFrame || 
# window.webkitRequestAnimationFrame ||
(fn) -> setTimeout fn,1000/60


# chacking mobile or not
isMobile = (navigator.userAgent.indexOf('iPhone') > 0 &&
navigator.userAgent.indexOf('iPad') == -1) ||
navigator.userAgent.indexOf('iPod') > 0 ||
navigator.userAgent.indexOf('Android') > 0

# page swiching or not
isWorking = false

# use pushState or not for Single-page Applicaito
spaPush = false;

# frame count until this web page started
frameCount = 0

# frame count until the virtual page started
pageFrameCount = 0

# mutated visual state elements on the virtual pages
speedElems = []

# cached section elements.
sections = []

# Current page Number( ONLY using lp-touch="back"/"next", it working.)
pageCount = 0

# Max page counts.
maxPageCount = 0

# Next section element, when switching virtual page.
after = null

# Last section element, when switching virtual page.
before = null

# for plugins
window.LEAPING = { actions : {}, PAGE_CHANGE_TIME : PAGE_DELAY };

#######################################
# Set default CSS Values
setDefaultCSS = () ->
	style = document.createElement "style"
	style.textContent = """
		html,body {
			margin : 0;
			padding : 0;
			background-color : black;
			color : white;
			overflow : hidden;
			width : 100%;
			height: 100%;
		}
		html {
			touch-action : none;
		}
		section {
			display : none;
			position : fixed;
			top : 0%;
			left : 0%;
			width : 100%;
			height : 100%;
			background-repeat : no-repeat;
			background-position : center center;
			background-size : cover;
			text-align : center;
		}
		.lpBlock {
			position : fixed;
			dipslay : block;
			width : 100%;
			left : 0%;
			top : 0%;
			text-align : center;
			margin : 0;
			padding : 0;
		}
		.nowloading {
			display : block;
			position : fixed;
			top : 0%;
			left : 0%;
			width : 100%;
			height : 100%;
			background-color: black;
		}
		.nowloading>.progress {
			position : absolute;
			bottom : 2%;
			right : 2%;
			width :100%;
			text-align : right;
		}
		.nowloading>.progress>.logo {
			display : inline-block;
			width : 16px;
			height : 16px;
		}
	"""
	(document.querySelector "head").appendChild style
	return

#######################################
# Show Loading View.
showLoadView = () ->
	nowLoading = document.createElement "div"
	nowLoading.setAttribute "class","nowloading"
	nowLoading.innerHTML = """
		<div class='progress'>Now Loading (<span class='percent'>0</span>%)</div>
	"""
	(document.querySelector "body").appendChild nowLoading
	return

#######################################
# Move Loading View.(Actially show the progress for loading resources.)
moveProgressView = () ->
	images = document.querySelectorAll "img"
	loadView = document.querySelector ".nowloading"
	percent  = loadView.querySelector ".percent"
	imageList = []
	allElems = document.getElementsByTagName "*"
	for image in images
		imageList.push (image.getAttribute "src")
	for elem in allElems
		convertParams elem
		bg = elem.getAttribute "lp-bg"
		if bg
			imageList.push bg
	cnt = 0
	for url in imageList
		img = document.createElement "img"
		img.onload = () ->
			cnt++
			percent.textContent = parseInt((cnt*100)/imageList.length)
			if imageList.length <= cnt
				fadeOut loadView
				showFirstSection()
		img.onerror = () ->
			alert "Can't load resource -> " + url
		img.src = url

	return

#######################################
# Fade out the element
fadeOut = (elem) ->
	beginFrame = 0
	maxFrame = 120.0
	work = () ->
		beginFrame++
		if maxFrame < beginFrame
			clearInterval timer
			elem.style.opacity = 0.0
			elem.style.display = "none"
		else
			elem.style.opacity = (maxFrame-beginFrame)/maxFrame
	timer = setInterval work, 1000/60
	return

#######################################
# Convert lp-* params and set Data
convertParams = (elem) ->
	classStr = elem.getAttribute "class"
	if ! classStr
		classStr = ""
	bg = elem.getAttribute "lp-bg"
	if bg
		elem.style.backgroundImage = "url("+bg+")"
	x = elem.getAttribute "lp-x"
	if x
		elem.setAttribute "class", classStr+" lpBlock"
		elem.style.left = x+"%"
	y = elem.getAttribute "lp-y"
	if y
		elem.setAttribute "class", classStr+" lpBlock"
		elem.style.top = y+"%"
	if elem.getAttribute "lp-speed"
		elem.setAttribute "lp-text", elem.textContent
	touch = elem.getAttribute "lp-touch"
	if touch
		if touch == "next"
			elem.addEventListener "click",gotoNextSection
		else if touch == "back"
			elem.addEventListener "click",goBackToLastSection
		else
			lst = touch.split(":")
			if lst[0] == "goto"
				elem.addEventListener "click",gotoTargetId
	return

#######################################
# Move for frame
moveFrame = () ->
	frameCount++
	pageFrameCount++
	for elem in speedElems
		count = (pageFrameCount-PAGE_DELAY)*parseInt(elem.getAttribute "lp-speed")*0.02
		elem.textContent = (elem.getAttribute "lp-text").substring(0,count)
	if pageFrameCount <= PAGE_DELAY
		isWorking = true
		action = null
		action = after.getAttribute "lp-action"
		if action
			if window.LEAPING.actions[action]
				window.LEAPING.actions[action](before, after, pageFrameCount)
			else
				before.style.opacity = 1.0
				before.style.display = "none"
				after.style.opacity = 1.0
				after.style.display = "block"
				pageFrameCount = PAGE_DELAY
		else
			if pageFrameCount < PAGE_DELAY/2
				maxTime = PAGE_DELAY/2
				before.style.transform = "scale("+(2.0+Math.cos(Math.PI/(1.0+(pageFrameCount/maxTime))))+")"
				before.style.opacity = ((maxTime-pageFrameCount)/(maxTime*1.0))
			else
				if before
					before.style.display = "none"
				maxTime = PAGE_DELAY/2
				currentFrame = pageFrameCount-maxTime
				after.style.display = "block"
				after.style.transform = "scale("+(Math.sin(Math.PI/(1.0+(currentFrame/maxTime))))+")"
				after.style.opacity = 1.0-((maxTime-currentFrame)/(maxTime*1.0))
	else
		isWorking = false
	nextFrame moveFrame
	return

#######################################
# Get the elements which have lp-speed attribute
getSpeedElement = (elem) ->
	list = []
	elems = elem.getElementsByTagName "*"
	for d in elems
		speed = d.getAttribute "lp-speed"
		if speed
			list.push d
	return list

#######################################
# change video tag's playing state
switchVideoState = () ->
	if isMobile
		return
	if before 
		video = before.querySelector "video"
		if video
			video.pause()
	if after
		video = after.querySelector "video"
		if video
			video.play()
	return

#######################################
# Show first <section>
showFirstSection = () ->
	pageFrameCount = PAGE_DELAY/2
	pageCount = 0
	sections = document.querySelectorAll "section"
	maxPageCount = sections.length
	after = sections[pageCount]
	speedElems = getSpeedElement after
	after.style.display = "block"
	moveFrame()
	switchVideoState()
	if spaPush && afterId
		history.pushState({id:afterId}, null, "#"+afterId);
	return

#######################################
# Go to next <section>
gotoNextSection = () ->
	if isWorking
		return
	pageFrameCount = 0
	before = sections[pageCount]
	pageCount++
	if maxPageCount <= pageCount
		pageCount = 0
	after = sections[pageCount]
	speedElems = getSpeedElement after
	switchVideoState()

	afterId = after.getAttribute "id"
	return

#######################################
# Go back to last <section>
goBackToLastSection = () ->
	if isWorking
		return
	pageFrameCount = 0
	before = sections[pageCount]
	pageCount--
	if pageCount < 0
		pageCount = maxPageCount-1
	after = sections[pageCount]
	speedElems = getSpeedElement after
	switchVideoState()
	return

#######################################
# Go to target <section> by id
gotoTargetId = () ->
	if isWorking
		return
	lst = (this.getAttribute "lp-touch").split(":")
	afterId = lst[1]
	switchPage afterId
	if spaPush
		history.pushState({id:afterId}, null, "#"+afterId);	
	return

#######################################
# Switch Page by Element ID
switchPage = (afterId) ->
	before = after
	after = document.querySelector "#"+afterId

	pageFrameCount = 0
	speedElems = getSpeedElement after
	switchVideoState()
	return


#######################################
# set styles for each elements.
setCSS = (elems,styleName,value) ->
	for elem in elems
		elem.style[styleName] = value
	return


#######################################
# Initialize before all of the elements are loaded.
delayInit = () ->
	if document.querySelector("body").getAttribute("lp-push") && window.history.pushState
		spaPush = true
		window.addEventListener 'popstate', popEvent
	showLoadView()
	moveProgressView()
	return

#######################################
# for popState events.
popEvent = (evt) ->
	state = evt.state
	if state.id
		switchPage state.id
	return


#######################################
# execute this program.
init = () ->
	setDefaultCSS();
	return


init()
document.addEventListener "DOMContentLoaded", delayInit

