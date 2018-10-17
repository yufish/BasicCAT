﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub


Sub changeFontsFromEnToZhOfStyleFile(ParsedData As Map)
	Dim GroupName,styleName As String
	For i=0 To 1
		If i=0 Then
			GroupName="RootCharacterStyleGroup"
			styleName="CharacterStyle"
		Else
			GroupName="RootParagraphStyleGroup"
			styleName="ParagraphStyle"
		End If

		Dim root As Map = ParsedData.Get("idPkg:Styles")
		Dim styleGroup As Map = root.Get(GroupName)
		Dim styles As List
		styles=Utils.GetElements(styleGroup,styleName)
		For Each style As Map In styles
			Dim attributes As Map
			attributes=style.Get("Attributes")
			Dim name As String
			name=attributes.Get("Name")

			If attributes.ContainsKey("FontStyle") Then
				Dim FontStyle As String
				FontStyle=attributes.Get("FontStyle")

				If Regex.Matcher("[0-9]",FontStyle).Find Then
					Dim weight As String
					Dim matcher As Matcher
					matcher=Regex.Matcher("[0-9]",FontStyle)
					Do While matcher.Find
						weight=weight&matcher.Match
					Loop
					FontStyle=FontWeightNumToNameForSourceHS(weight)
					
				End If
				FontStyle=FontWeightNameToNameForSourceHS(FontStyle)
				attributes.Put("FontStyle",FontStyle)
			End If
			

			If style.ContainsKey("Properties") Then
				Dim Properties,AppliedFont As Map
				Properties=style.Get("Properties")
				If Properties.ContainsKey("AppliedFont") Then
					AppliedFont=Properties.get("AppliedFont")
					Log("font "&AppliedFont.Get("Text"))
					AppliedFont.Put("Text","思源宋体")
					'Properties.Put("AppliedFont",AppliedFont)
					'characterStyle.Put("Properties",Properties)
				End If
			End If
		Next
	Next

End Sub


Sub FontWeightNumToNameForSourceHS(weight As Int) As String
	Log(weight)
	Select weight
		Case 100
			Return "ExtraLight"
		Case 200
			Return "ExtraLight"
		Case 300
			Return "Light"
		Case 400
			Return "Regular"
		Case 500
			Return "Medium"
		Case 600
			Return "SemiBold"
		Case 700
			Return "Bold"
		Case 800
			Return "Heavy"
		Case 900
			Return "Heavy"
	End Select
	Return "Regular"
End Sub

Sub FontWeightNameToNameForSourceHS(name As String) As String
	Select name
		Case "Normal"
			Return "Regular"
		Case "Black"
			Return "Heavy"
	End Select
	Return name
End Sub


Sub mergeInWordPartForparaStyleRange(paragraphText As String) As String
	Log("paragraphText"&paragraphText)
	Dim matcher2 As Matcher
	matcher2=Regex.Matcher("(?s)<c\d+.*?>.*?</c\d+>",paragraphText)
	Dim characterTextList As List
	characterTextList.Initialize
	Do While matcher2.Find
		characterTextList.Add(matcher2.Match)
	Loop
	removeBrInContentList(characterTextList)
	Dim num As Int=0
	Log("start")
	Do While containsMergableParts(characterTextList)
		num=num+1
		Log(num)
		Dim newList As List
		newList.Initialize
		Dim index As Int=-1
		Dim added As Boolean=False
		For Each characterText As String In characterTextList
			index=index+1
			If added Then
				added=False
				Continue
			End If
			Dim tagMatcher As Matcher
			tagMatcher=Regex.Matcher("<c(\d+) id=",characterText)
				
			If tagMatcher.Find Then
				If index=characterTextList.Size-1 Then
					newList.Add(characterText)
					Continue
				End If
					
				Dim id As Int
				id=tagMatcher.Group(1)

				Dim nextCharacterText As String
				nextCharacterText=characterTextList.Get(index+1)
					
				Dim tagMatcher2 As Matcher
				tagMatcher2=Regex.Matcher("<c(\d+) id=",nextCharacterText)
				If tagMatcher2.Find Then
					If tagMatcher2.Group(1)=id Then
						Dim innerText1,innerText2,new As String
						innerText1=removeTags(characterText)
						innerText2=removeTags(nextCharacterText)
						If innerText1.Trim="" Then
							Continue
						End If
						If countMatches(innerText1," ")<=1 And countMatches(innerText2," ")<=1 Then
							new=innerText1&innerText2
							Log(characterText)
							Log(nextCharacterText)
							Log(innerText1)
							Log(innerText2)
							Log("new"&new)
							added=True
							characterText=characterText.Replace(innerText1,new)
						Else if innerText1.EndsWith(" ") Then
							new=innerText1&" "&innerText2
							characterText=characterText.Replace(innerText1,new)
							added=True
						End If
					End If
				End If
			End If
			newList.Add(characterText)
		Next
		characterTextList.Clear
		characterTextList.AddAll(newList)

	Loop
		
	paragraphText=""
	For Each text As String In characterTextList
		paragraphText=paragraphText&text&CRLF&CRLF
	Next
	Return paragraphText
End Sub


Sub containsMergableParts(characterTextList As List) As Boolean
	Dim result As Boolean=False
	Dim index As Int=-1
	For Each characterText As String In characterTextList
		index=index+1
		Log(characterText)
		Log(index)
		Dim tagMatcher As Matcher
		tagMatcher=Regex.Matcher("<c(\d+) id=",characterText)
		
		If tagMatcher.Find Then
			
			If index=characterTextList.Size-1 Then
				Continue
			End If
			Dim id As Int
			id=tagMatcher.Group(1)
			Dim nextCharacterText As String
			nextCharacterText=characterTextList.Get(index+1)
						
			Dim tagMatcher2 As Matcher
			tagMatcher2=Regex.Matcher("<c(\d+) id=",nextCharacterText)
			If tagMatcher2.Find Then
				If tagMatcher2.Group(1)=id Then
					Dim innerText1,innerText2 As String
					innerText1=removeTags(characterText)
					innerText2=removeTags(nextCharacterText)
					If innerText1.Trim="" Then
						Continue
					End If
					If countMatches(innerText1," ")<=1 And countMatches(innerText2," ")<=1 Then
						result=True
					Else if innerText1.EndsWith(" ") Then
						result =True
					End If
				End If

			End If
		End If
	Next
	Return result
End Sub

Sub removeTags(text As String) As String
	Dim matcher As Matcher
	matcher=Regex.Matcher("<.*?>",text)
	Do While matcher.Find
		Log("match"&matcher.Match)
		text=text.Replace(matcher.Match,"")
	Loop
	Return text
End Sub

Sub countMatches(str As String,substr As String) As Int
	Dim count As Int=0
	Dim su As ApacheSU
	Do While str.Contains(substr)
		count=count+1
		str=su.ReplaceOnce(str,substr,"")
	Loop
	Return count
End Sub


Sub removeBrInContentList(ContentList As List)
	Dim newlist As List
	newlist.Initialize
	For i=0 To ContentList.Size-1
		Dim content As String
		content=ContentList.Get(i)
		If content.Trim<>"" Then
			newlist.Add(content)
		End If
	Next
	ContentList.Clear
	ContentList.AddAll(newlist)
End Sub