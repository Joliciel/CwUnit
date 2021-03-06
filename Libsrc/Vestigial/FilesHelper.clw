  MEMBER()
  
! ASSERTs with eqDBG rely on a System{AssertHook2} to turn these into debugging calls (see Debuger.inc)
!   they will only work when in debug mode, or with pragma asserts=>on
EQDBG EQUATE('<4,2,7>')

  MAP
  	MODULE('API')
  	   GetDriveType(*CSTRING lpRootPathName),UNSIGNED,PASCAL,RAW,NAME('GetDriveTypeA')   !!http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/fs/getdrivetype.asp
      FnSplit(*CSTRING InPath, *CSTRING OutDriv,*CSTRING OutDir,*CSTRING OutName,*CSTRING OutExtension),SHORT,RAW,NAME('_fnsplit'),proc     !doc on page 266 of topspeed C reference !<-- in the RTL, no pascal,raw

      GetTempFileName( *CSTRING lpPathName, *CSTRING lpPrefixString, UNSIGNED uUnique, *CSTRING lpTempFileName ),UNSIGNED,RAW,PASCAL,NAME('GetTempFileNameA')
      GetTempPath    ( LONG nBufferLength, *? lpBuffer ),LONG,RAW,PASCAL,NAME('GetTempPathA')
  	END
  END
  
  INCLUDE('FilesHelper.inc'),ONCE


!Region StaticFilesHelper
  
  !TODO: see CWUtil.GetFileTime and .GetFileDate which are based on FindFirstFile, FileTimeToLocalFileTime, FileTimeToSystemTime
 
StaticFilesHelper.Exists               PROCEDURE(STRING FileName)!,BOOL
 	CODE
 	RETURN Exists(FileName)
 
!=============================================================================
StaticFilesHelper.EnsureEndsWith                PROCEDURE(  STRING Current, STRING EndsWith)!,STRING 
   !FileName = FileHelper.EnsureEndsWith(FileName,'\')
	CODE
	IF SUB(   CLIP(Current), -SIZE(EndsWith), SIZE(EndsWith) ) = EndsWith
	   RETURN CLIP(Current) 
	END
	RETURN    CLIP(Current) & EndsWith
	

!=============================================================================
StaticFilesHelper.FnSplit                 PROCEDURE(STRING xPath, <*STRING xaDrive>, <*STRING xaDir>, <*STRING xaName>, <*STRING xaExt>)
PARAM::xaDrive EQUATE(3) !Pre C6 approach to OMITTED()
PARAM::xaDir   EQUATE(4)
PARAM::xaName  EQUATE(5)
PARAM::xaExt   EQUATE(6)

Info  LIKE(gtFnSplit)
  CODE
  Info._Path = xPath
  SELF.FnSplit(Info)
  IF ~OMITTED(PARAM::xaDrive) THEN xaDrive = Info._Drive END
  IF ~OMITTED(PARAM::xaDir  ) THEN xaDir   = Info._Dir   END
  IF ~OMITTED(PARAM::xaName ) THEN xaName  = Info._Name  END
  IF ~OMITTED(PARAM::xaExt  ) THEN xaExt   = Info._Ext   END

  !=============================================================================
StaticFilesHelper.FnSplit               PROCEDURE(*gtFnSplit SplitFile)
  CODE
  FnSplit( SplitFile._Path, SplitFile._Drive, SplitFile._Dir, SplitFile._Name, SplitFile._Ext)
  
  !I noticed that *some* of the fields were clipped, So I decided to be consistent and clip them all.  
  SplitFile._Path  = CLIP( SplitFile._Path  )
  SplitFile._Drive = CLIP( SplitFile._Drive )
  SplitFile._Dir   = CLIP( SplitFile._Dir   )
  SplitFile._Name  = CLIP( SplitFile._Name  )
  SplitFile._Ext   = CLIP( SplitFile._Ext   )


!===========================================================
StaticFilesHelper.ToString              PROCEDURE(CONST *gtFnSplit SplitFile, STRING Delimiter)
  CODE
  RETURN 'Path ['& CLIP( SplitFile._Path  ) &']' & Delimiter & |
         'Drive['& CLIP( SplitFile._Drive ) &']' & Delimiter & |
         'Dir  ['& CLIP( SplitFile._Dir   ) &']' & Delimiter & |
         'Name ['& CLIP( SplitFile._Name  ) &']' & Delimiter & |
         'Ext  ['& CLIP( SplitFile._Ext   ) &']' 


StaticFilesHelper.AbsoluteFileName        PROCEDURE(*gtFnSplit Info)!,STRING
  CODE
  SELF.FnSplit(Info)
  RETURN Info._Drive & Info._Dir & Info._Name & Info._Ext

!=============================================================================
StaticFilesHelper.DriveDir                PROCEDURE(STRING xPath)!,STRING
Info  LIKE(gtFnSplit)
  CODE
  Info._Path = xPath
  SELF.FnSplit(Info)
  RETURN Info._Drive & Info._Dir

!=============================================================================
StaticFilesHelper.BaseName                PROCEDURE(STRING xPath)!,STRING
Info  LIKE(gtFnSplit)
  CODE
  Info._Path = xPath
  SELF.FnSplit(Info)
  RETURN Info._Name & Info._Ext

!=============================================================================
StaticFilesHelper.Extension              PROCEDURE(STRING xPath)!,STRING
Info  LIKE(gtFnSplit)
  CODE
  Info._Path = xPath
  SELF.FnSplit(Info)
  RETURN Info._Ext






!====================================================================================
StaticFilesHelper.GetTempPath        PROCEDURE() !,STRING
!COPIED out of c8\cwutil.clw, with minor changes

Result        STRING(FILE:MaxFilePath),AUTO
lPathSize     LONG,AUTO

  CODE
  lPathSize = GetTempPath ( SIZE (Result), Result )
  IF lPathSize = 0 OR lPathSize > SIZE (Result)
     RETURN ''
  END
  RETURN Result [ 1 : lPathSize ]


!====================================================================================
StaticFilesHelper.GetTempFileName                         PROCEDURE( STRING xPrefix )!,STRING
szPath             CSTRING(FILE:MaxFilePath),AUTO
  CODE
  szPath = SELF.GetTempPath()
  IF CLIP( szPath ) = ''
           szPath = '.'
  END

  RETURN SELF.GetTempFileName(xPrefix, szPath)

!====================================================================================
StaticFilesHelper.GetTempFileName                         PROCEDURE( STRING xPrefix, STRING xDirectory )
!COPIED out of c8\cwutil.clw, with minor changes

szPrefix   CSTRING( 4 ),AUTO
szResult   CSTRING(FILE:MaxFilePath),AUTO
szPath     CSTRING(FILE:MaxFilePath),AUTO

  CODE
  													! ASSERT(0,eqDBG&'xPrefix['& xPrefix &'] xDir['& xDirectory & ']') 
  szPath   = CLIP( xDirectory )

  szPrefix = CLIP( xPrefix )
  IF LEN(CLIP(xPrefix)) > SIZE(szPrefix) - 1
     MESSAGE('.GetTempFileName Prefix['& CLIP(xPrefix) &'] Truncated to ['& szPrefix &']','Programmer Error',ICON:Exclamation)
  END
  IF szPrefix = ''
     szPrefix = '$$$'
  END 
  
  IF GetTempFileName( szPath, szPrefix, 0, szResult ) = 0
     ASSERT(0,eqDBG&'GetTempFileName - FAILED')
     ASSERT(0,eqDBG&'xPrefix['& xPrefix &'] szPrefix['& szPrefix &'] xDir['& xDirectory & '] szPath['& szPath &']') 
     RETURN ''
  END  
  													! ASSERT(0,eqDBG&'GetTempFileName szResult['& szResult &']')  
  RETURN CLIP( szResult )


!=============================================================================
StaticFilesHelper.GetDriveType           PROCEDURE(STRING xRootPathName)
  !http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/fs/getdrivetype.asp
  !consider: wNetGetConnection and WNetGetUniversalName  (see .public.clarion6  thread "Real Path" Aug/9/06)

szRootPathName   CSTRING( FILE:MaxFilePath )
Info             LIKE(gtFnSplit)
RetVal           UNSIGNED !UINT
  CODE
                                                      ! ASSERT(0,eqDBG&'v .GetDriveType -------[start]-------')
  IF SUB(xRootPathName, 1,2) = '\\'
     RetVal = DRIVE_REMOTE                            !;ASSERT(0,eqDBG&'   UNC, returning DRIVE_REMOTE')
  ELSE
     Info._Path = xRootPathName                       !;ASSERT(0,eqDBG&'   .GetDriveType xRootPathName['& CLIP(xRootPathName) &']')
     SELF.FnSplit(Info)                               !;ASSERT(0,eqDBG&'   .GetDriveType _Drive['& CLIP( Info._Drive ) &']')
     Info._Drive = SELF.EnsureEndsWith(Info._Drive, '\')     
     RetVal = GetDriveType( Info._Drive )             !;ASSERT(0,eqDBG&'^  mg.GetDriveType RetVal['& RetVal &']')
  END
  RETURN RetVal



  

!=======================================================================================================================
StaticFilesHelper.FILE:Multi_ToFileListQ          PROCEDURE(STRING xsFileList, *qtFileList xaFileListQ, STRING xsDelim) !assumes FILE:Multi notation:     folder|file1.txt|file2.txt

  !Just ADDs to the QUEUE - you can do your own FREE(Q)
nDropLen       LONG,AUTO
CurrChar       LONG(1)
NextChar       LONG,AUTO
szFolder       CSTRING(FILE:MaxFilePath)
  CODE
  szFolder=''
                                                                                   !   ASSERT(0,eqDBG&'StaticFilesHelper.MultiFileToFileListQ xsDelim['& xsDelim &']')
  !          ASSERT(0,eqDBG&'xsFileList['& xsFileList &']')
  LOOP
    NextChar = INSTRING(xsDelim,xsFileList,1,CurrChar)                             ! ; ASSERT(0,eqDBG&'CurrChar['& CurrChar &'] NextChar['& NextChar &']')
    IF ~NextChar THEN BREAK END

    IF CurrChar = 1
         szFolder          =            xsFileList[1        : NextChar - 1] & '\'  ! ; ASSERT(0,eqDBG&'Setting Folder, szFolder['& szFolder &']')
    ELSE xaFileListQ.Fname = szFolder & xsFileList[CurrChar : NextChar - 1]
         ADD(xaFileListQ)                                                          ! ; ASSERT(0,eqDBG&'Adding['& xaFileListQ.Fname &']')
    END

    CurrChar  = NextChar + 1
  END

  nDropLen = SIZE(xsFileList)                                                      !; ASSERT(0,eqDBG&'CurrChar['& CurrChar &'] NextChar['& NextChar &'] nDropLen['& nDropLen &'] - Final')
  IF CurrChar <= nDropLen
     xaFileListQ.Fname = szFolder & xsFileList[CurrChar : nDropLen]
     ADD(xaFileListQ)                                                             ! ; ASSERT(0,eqDBG&'Adding['& xaFileListQ.Fname &']')
  END


!=======================================================================================================================
StaticFilesHelper.DropIDFile_ToFileListQ          PROCEDURE(STRING xsFileList, *qtFileList xaFileListQ, STRING xsDelim) !+Dec/12/08  !assumes ~FILE notation
  !Just ADDs to the QUEUE - you can do your own FREE(Q)
nDropLen       LONG,AUTO
CurrChar       LONG(1)
NextChar       LONG,AUTO
StartChar      LONG(1)
  CODE
                                                                         !   ASSERT(0,eqDBG&'StaticFilesHelper.StrToFileListQ xsDelim['& xsDelim &']')
                                                                         !   ASSERT(0,eqDBG&'xsFileList['& xsFileList &']')
  LOOP
    NextChar = INSTRING(xsDelim,xsFileList,1,StartChar)                  ! ; ASSERT(0,eqDBG&'CurrChar['& CurrChar &'] StartChar['& StartChar &'] NextChar['& NextChar &']')
    IF ~NextChar THEN BREAK END

    !The following distinguishes between xsDelim (~File uses a ',') IN a filename, vs. a delimeter between filenames
    ! all filenames start with either:   \\ or X:
    IF ( SUB(xsFileList, NextChar + 1,2)='\\')                                               OR |
       ( SUB(xsFileList, NextChar + 2,1)=':' AND ISALPHA( SUB(xsFileList, NextChar + 1,1)) )    |
    THEN
       xaFileListQ.Fname = xsFileList[CurrChar : NextChar - 1]
       ADD(xaFileListQ)                                                  !; ASSERT(0,eqDBG&'Adding['& xaFileListQ.Fname &']')
       CurrChar  = NextChar + 1
       StartChar = CurrChar
    ELSE
                                   													!ASSERT(0,eqDBG&'Was it \\ ['& CHOOSE( SUB(xsFileList, NextChar + 1,2)='\\' ) &']')
                                   													!ASSERT(0,eqDBG&'Was it x: ['& CHOOSE( (  SUB(xsFileList, NextChar + 2,1)=':' AND ISALPHA( SUB(xsFileList, NextChar + 1,1)) ) ) &']')
       StartChar = NextChar + 1    ! the xaDelim (',') we found was part of a filename it was *not* a delimiter
    END
  END

  nDropLen = SIZE(xsFileList)                                            !  ; ASSERT(0,eqDBG&'CurrChar['& CurrChar &'] NextChar['& NextChar &'] nDropLen['& nDropLen &'] - Final')
  IF CurrChar <= nDropLen
     xaFileListQ.Fname = xsFileList[CurrChar : nDropLen]
     ADD(xaFileListQ)                                                    !  ; ASSERT(0,eqDBG&'Adding['& xaFileListQ.Fname &']')
  END

  
!EndRegion StaticFilesHelper

!=================================================================
!=================================================================
!=================================================================
!=================================================================
 
!Region ctFilesHelper
 
ctFilesHelper.AbsoluteFileName    PROCEDURE()!,STRING
   CODE
   RETURN SELF.SplitInfo._Drive & SELF.SplitInfo._Dir & SELF.SplitInfo._Name & SELF.SplitInfo._Ext
   
ctFilesHelper.SetFileName          PROCEDURE(STRING newFileName)
 	CODE
 	SELF.SplitInfo._Path = newFileName
 	SELF.FnSplit( SELF.SplitInfo )
 
ctFilesHelper.Exists               PROCEDURE()
 	CODE
 	RETURN SELF.Exists(SELF.SplitInfo._Path)
 
ctFilesHelper.DriveDir                PROCEDURE()!,STRING
	CODE
	RETURN SELF.SplitInfo._Drive & SELF.SplitInfo._Dir
	
ctFilesHelper.BaseName                PROCEDURE()!,STRING
	CODE
	RETURN SELF.SplitInfo._Name & SELF.SplitInfo._Ext
	
ctFilesHelper.Extension               PROCEDURE()!,STRING
	CODE
	RETURN SELF.SplitInfo._Ext

ctFilesHelper.ToString                PROCEDURE(<STRING Delimiter>)!,STRING
	CODE
	IF OMITTED(Delimiter)
	   RETURN SELF.ToString(SELF.SplitInfo, ' ')
	END
	   RETURN SELF.ToString( SELF.SplitInfo, Delimiter)
 
!EndRegion FilesHelper 
