EnableExplicit

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

If OpenConsole()
  If CountProgramParameters() And ProgramParameter(0) <> "-h" And ProgramParameter(0) <> "--help"
    Define.s mode, repoUrl, releaseTag, assetName, releaseUrl
    Define.i i, releaseNumber, assetNumber, releasesNumber

    mode = ProgramParameter(3)
    repoUrl = clearUrl(ProgramParameter(0))

    If ProgramParameter(1)
      releaseNumber = Val(ProgramParameter(1))
    EndIf

    If ProgramParameter(2)
      assetNumber = Val(ProgramParameter(2))
    EndIf

    If parseReleases(repoUrl)
      releasesNumber = ArraySize(releasesArray())

      If releaseNumber And releaseNumber - 1 > releasesNumber - 1
        PrintN("Incorrect release number")
        End
      EndIf

      If assetNumber And assetNumber + 2 > CountString(releasesArray(releaseNumber - 1), ":") + 1
        PrintN("Incorrect asset number")
        End
      EndIf

      If assetNumber
        releaseTag = StringField(releasesArray(releaseNumber - 1), 1, ":")
        assetName = StringField(releasesArray(releaseNumber - 1), assetNumber + 2, ":")
        releaseUrl = "https://github.com/" + repoUrl + "/releases/download/" + releaseTag + "/" + assetName

        If mode = "download"
          If ReceiveHTTPFile(releaseUrl, assetName)
            PrintN("Download completed successfully.")
          Else
            PrintN("Download failed.")
          EndIf
        Else
          PrintN(releaseUrl)
        EndIf
      ElseIf releaseNumber
        PrintN("Available assets:")
        PrintN("")

        For i = 3 To CountString(releasesArray(releaseNumber - 1), ":") + 1
          PrintN(Str(i - 2) + ". " + StringField(releasesArray(releaseNumber - 1), i, ":"))
        Next
      Else
        PrintN("Available releases and assets:")
        PrintN("")

        Define.i k

        For i = 0 To releasesNumber - 1
          PrintN(Str(i + 1) + ". " + StringField(releasesArray(i), 2, ":"))

          For k = 3 To CountString(releasesArray(i), ":") + 1
            PrintN("    " + Str(k - 2) + ". " + StringField(releasesArray(i), k, ":"))
          Next
        Next
      EndIf
    Else
      PrintN("Unable to find releases")
      PrintN("")
      PrintN("This repo doesn't exist or doesn't have releases, or you have no internet connection.")
    EndIf
  Else
    PrintN("Usage: releases-downloader RepoUrl ReleaseNumber AssetNumber")
    PrintN("")
    PrintN("If ReleaseNumber or AssetNumber are not specified, the program will show all available numbers.")
    PrintN("")
    PrintN("Instead of specifying a full GitHub repository URL, you can just use the short 'owner/reponame' format.")
    PrintN("")
    PrintN("By default the program will only show a direct link suitable to download a release, but will not download it. You can use the link with other programs (for example, with wget).")
    PrintN("")
    PrintN("If you want the program to download a release, you can add 'download' as the last argument (after AssetNumber).")
  EndIf
EndIf
