EnableExplicit

Define.i i, k, repoUrlGadget, releasesButton, releasesGadget, downloadButton, showUrlButton, assetsGadget, gadgetItem, Event
Define.s repoUrl, releaseTag, assetName

Procedure.i parseReleases(url.s)
  Protected *FileBuffer
  Protected.i jarraySize, jsonElement, jsonObject, jsonFile, i, k, assetsJsonArray
  Protected.s releaseName, tagName, assetsString
  Protected.s stringDelimiter = ":"

  InitNetwork()

  *FileBuffer = ReceiveHTTPMemory("https://api.github.com/repos/" + url + "/releases?per_page=100")

  If *FileBuffer
    jsonFile = ParseJSON(#PB_Any, PeekS(*FileBuffer, MemorySize(*FileBuffer), #PB_UTF8))

    If MemorySize(*FileBuffer) < 50
      FreeMemory(*FileBuffer)
      ProcedureReturn 0
    EndIf

    FreeMemory(*FileBuffer)

    If jsonFile
      jsonObject = JSONValue(jsonFile)

      If JSONType(jsonObject) = #PB_JSON_Array
        jarraySize = JSONArraySize(jsonObject)

        Global Dim releasesArray.s(jarraySize)

        For i = 0 To jarraySize - 1
          jsonElement = GetJSONElement(jsonObject, i)
          releaseName = GetJSONString(GetJSONMember(jsonElement, "name"))
          tagName = GetJSONString(GetJSONMember(jsonElement, "tag_name"))

          assetsJsonArray = GetJSONMember(jsonElement, "assets")

          assetsString = ""
          If assetsJsonArray
            For k = 0 To JSONArraySize(assetsJsonArray) - 1
              assetsString + stringDelimiter + GetJSONString(GetJSONMember(GetJSONElement(assetsJsonArray, k), "name"))
            Next
          EndIf

          releasesArray(i) = tagName + stringDelimiter + releaseName + assetsString
        Next

        ProcedureReturn 1
      EndIf

      FreeJSON(jsonFile)
    EndIf
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

Procedure.s clearUrl(url.s)
  Protected.s newUrl = url
  Protected Dim stringsToRemove.s(5)
  Protected.i i

  stringsToRemove.s(0) = "https://"
  stringsToRemove.s(1) = "github.com/"
  stringsToRemove.s(2) = "/releases"
  stringsToRemove.s(3) = "/releases/latest"
  stringsToRemove.s(4) = "//"

  For i = 0 To ArraySize(stringsToRemove()) - 1
    If FindString(newUrl, stringsToRemove(i))
      newUrl = ReplaceString(newUrl, stringsToRemove(i), "")
    EndIf
  Next

  FreeArray(stringsToRemove())

  ProcedureReturn newUrl
EndProcedure

If OpenWindow(0, #PB_Ignore, #PB_Ignore, 300, 85, "Releases Downloader")
  repoUrlGadget = StringGadget(#PB_Any, 5, 5, 290, 30, "")
  releasesButton = ButtonGadget(#PB_Any, 5, 45, 290, 30, "Show releases")

 If LoadFont(0, "Arial", 10, #PB_Font_Bold)
    SetGadgetFont(releasesButton, FontID(0))
  EndIf

  Repeat
    Event = WaitWindowEvent()

    If Event = #PB_Event_Gadget
      Select EventGadget()
        Case releasesButton
          repoUrl = GetGadgetText(repoUrlGadget)

          If repoUrl <> ""
            repoUrl = clearUrl(repoUrl)

            If parseReleases(repoUrl)
              If OpenWindow(1, #PB_Ignore, #PB_Ignore, 300, 120, "Releases Downloader")
                DisableWindow(0, 1)

                releasesGadget = ComboBoxGadget(#PB_Any, 5, 5, 290, 30)
                assetsGadget = ComboBoxGadget(#PB_Any, 5, 40, 290, 30)
               downloadButton = ButtonGadget(#PB_Any, 5, 80, 290, 30, "Download")

               DisableGadget(assetsGadget, 1)

               For i = 0 To ArraySize(releasesArray()) - 1
                 AddGadgetItem(releasesGadget, i, StringField(releasesArray(i), 1, ":"))
               Next

               SetGadgetState(releasesGadget, 0)

               If CountString(releasesArray(0), ":") >= 2
                  For k = 2 To CountString(releasesArray(0), ":")
                    AddGadgetItem(assetsGadget, -1, StringField(releasesArray(0), k + 1, ":"))
                  Next

                 SetGadgetState(assetsGadget, 0)
                 DisableGadget(assetsGadget, 0)
               EndIf
             EndIf
            Else
             MessageRequester("Error", "Unable to find releases" + #CRLF$ + #CRLF$ + "This repo doesn't exist or doesn't have releases," + #CRLF$ + "or you have no internet connection.")
            EndIf
          Else
            MessageRequester("Error", "Please enter a GitHub repository URL (or owner/reponame)")
          EndIf
        Case releasesGadget
          gadgetItem = GetGadgetState(releasesGadget)

          If CountString(releasesArray(gadgetItem), ":") >= 2
            ClearGadgetItems(assetsGadget)

            For k = 2 To CountString(releasesArray(gadgetItem), ":")
              AddGadgetItem(assetsGadget, -1, StringField(releasesArray(gadgetItem), k + 1, ":"))
            Next

            SetGadgetState(assetsGadget, 0)
            DisableGadget(assetsGadget, 0)
          Else
            ClearGadgetItems(assetsGadget)
            DisableGadget(assetsGadget, 1)
          EndIf
        Case downloadButton
          releaseTag = StringField(releasesArray(GetGadgetState(releasesGadget)), 1, ":")
          assetName = GetGadgetText(assetsGadget)

          If ReceiveHTTPFile("https://github.com/" + repoUrl + "/releases/download/" + releaseTag + "/" + assetName, assetName)
            MessageRequester("Success", "Download completed successfully.")
          Else
            MessageRequester("Error", "Download failed.")
          EndIf
      EndSelect
    EndIf

    If Event = #PB_Event_CloseWindow And EventWindow() = 1
      CloseWindow(1)
      FreeArray(releasesArray())
      DisableWindow(0, 0)
    EndIf

  Until Event = #PB_Event_CloseWindow And EventWindow() = 0
EndIf
