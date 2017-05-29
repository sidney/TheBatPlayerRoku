sub navigateToSearch()
    print "navigateToSearch()"
    m.keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    m.keyboarddialog.title= "Search for stations"
    m.keyboarddialog.visible = true
    m.keyboarddialog.buttons=["Search"]
    m.keyboarddialog.observeField("buttonSelected", "performStationSearch")

    m.key = m.keyboarddialog.keyboard
    m.key.showTextEditBox = true

    m.top.getParent().getparent().dialog = m.keyboarddialog
     m.keyboarddialog.setFocus(true)
end sub

sub performStationSearch()
    searchQuery = m.keyboarddialog.text

    m.top.getParent().getparent().dialog = invalid
    m.keyeyboarddialog = invalid

    m.searchWaitingDialog = createObject("roSGNode", "ProgressDialog")
    m.searchWaitingDialog.title = "Searching for " + searchQuery + "..."
    m.top.getParent().getparent().dialog = m.searchWaitingDialog

    m.searchTask = createObject("roSGNode", "StationSearchTask")
    m.searchTask.ObserveField("stations", "navigateToSearchResults")
    m.searchTask.query = searchQuery
    m.searchTask.control = "RUN"
    
end sub

sub navigateToSearchResults(event)
    print "navigateToSearchResults(event)"
    m.top.getParent().getparent().dialog = invalid
    m.searchWaitingDialog = invalid
    stations = event.getData()
    
    m.searchResultsScreen = m.top.createChild("SearchResultsPanel")
    m.searchResultsScreen.stations = stations
end sub
