sub navigateToSearch()
    ' print "navigateToSearch()"
    m.keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    m.keyboarddialog.title= "Search for stations"
    m.keyboarddialog.visible = true
    m.keyboarddialog.buttons=["Search"]
    m.keyboarddialog.observeField("buttonSelected", "performStationSearch")
    m.keyboarddialog.text = "rock"
    m.key = m.keyboarddialog.keyboard
    m.key.showTextEditBox = true

    m.global.scene.dialog = m.keyboarddialog
    m.keyboarddialog.setFocus(true)
end sub

sub performStationSearch()
    searchQuery = m.keyboarddialog.text

    m.global.scene.dialog = invalid
    m.keyeyboarddialog = invalid

    m.searchWaitingDialog = createObject("roSGNode", "ProgressDialog")
    m.searchWaitingDialog.title = "Searching for " + searchQuery + "..."
    m.global.scene.dialog = m.searchWaitingDialog

    m.searchTask = createObject("roSGNode", "StationSearchTask")
    m.searchTask.ObserveField("stations", "navigateToSearchResults")
    m.searchTask.query = searchQuery
    m.searchTask.control = "RUN"
    
end sub

sub navigateToSearchResults(event)
    ' print "navigateToSearchResults(event)"

    searchQuery = m.keyboarddialog.text

    m.global.scene.dialog = invalid
    m.searchWaitingDialog = invalid
    stations = event.getData()
    
    m.childScreen = m.top.createChild("SearchResultsPanel")
    m.childScreen.stations = stations
    m.childScreen.searchQuery = searchQuery
end sub
