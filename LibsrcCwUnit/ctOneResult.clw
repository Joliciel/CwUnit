   MEMBER

!Region Notices 
! ================================================================================
! Notice : Copyright (C) 2014, Mark Goldberg
!          Distributed under LGPLv3 (http://www.gnu.org/licenses/lgpl.html)
!
!    This file is part of CwUnit (https://github.com/MarkGoldberg/CwUnit)
!
!    CwUnit is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    CwUnit is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with CwUnit.  If not, see <http://www.gnu.org/licenses/>.
! ================================================================================
!EndRegion Notices 


   MAP
   END
   INCLUDE('CtOneResult.inc'),ONCE

    INCLUDE('ctOutputDebugString.inc'),ONCE
MOD:ODS      ctOutputDebugString


!==============================================================================
CwUnit_ctResult.CONSTRUCT        PROCEDURE
	CODE
	CLEAR(SELF.Output)
!==============================================================================
CwUnit_ctResult.DESTRUCT         PROCEDURE
   !Q: Do we need to clear the ANY's ? 
   !A: Not sure, but it can't hurt
 	CODE
 	CLEAR(SELF.Output) 
   CLEAR(SELF.Data1)
   CLEAR(SELF.Data2)
 	
 	
!==============================================================================
CwUnit_ctResult.StatusToString   PROCEDURE()!,STRING
	CODE
	RETURN SELF.StatusToString(SELF.Status)
	
!==============================================================================
CwUnit_ctResult.StatusToString   PROCEDURE(LONG Status)!,STRING
Answer CSTRING(20)
 CODE
 CASE Status
	OF Status:NotRun       ; Answer='NotRun'
	OF Status:Pass         ; Answer='Pass'
	OF Status:Fail         ; Answer='Fail'
	OF Status:Ignore       ; Answer='Ignore'
	OF Status:Inconclusive ; Answer='Inconclusive'
	OF Status:Running      ; Answer='Running'
	OF Status:Missing      ; Answer='Missing'
 ELSE                     ; Answer='???('& Status &')'
 END
 RETURN Answer

 	



! !==============================================================================
CwUnit_ctResult.SetStatus        PROCEDURE(LONG NewStatus, STRING Operator, <? Output>, ? DefaultOutput )
    CODE
    IF OMITTED(Output)
       SELF.SetStatus(NewStatus, DefaultOutput)
    ELSE
       SELF.SetStatus(NewStatus, Output)
    END
!==============================================================================
CwUnit_ctResult.SetStatus        PROCEDURE(LONG NewStatus, <? Output>)   
   CODE
   SELF.Status = NewStatus
   IF ~OMITTED(Output) 
       SELF.Output = SELF.Output & Output 
   END   
!==============================================================================
CwUnit_ctResult.Pass             PROCEDURE(<? Output>)
   CODE
   SELF.SetStatus(Status:Pass, Output)
   
!==============================================================================
CwUnit_ctResult.Fail             PROCEDURE(<? Output>)
   CODE
   SELF.SetStatus(Status:Fail , Output)
!==============================================================================
CwUnit_ctResult.Ignore           PROCEDURE(<? Output>)
   CODE
   SELF.SetStatus(Status:Ignore, Output)

!==============================================================================
CwUnit_ctResult.Inconclusive     PROCEDURE(<? Output>)
   CODE
   SELF.SetStatus(Status:Inconclusive, Output)



!==============================================================================
CwUnit_ctResult.DefaultOutput    PROCEDURE(*? LHS, STRING Operator, <*? RHS>)!,STRING!,VIRTUAL
   CODE
   ! CASE Operator
   !   OF Is:Null    
   ! OROF Is:NotNull ; RETURN SELF.IsNullToString(LHS)
   ! END

   IF OMITTED(RHS) ; RETURN Operator & '(' & LHS & ')'
   END
                     RETURN '['& LHS &'] ' &  Operator & ' ['& RHS &']'



!==============================================================================
CwUnit_ctResult.Evaluate         PROCEDURE(*? Actual, STRING  UnaryOperator)!,BOOL
RetIsTrue BOOL
   CODE
   CASE UnaryOperator
     OF Is:True             ; RetIsTrue =  CHOOSE(     Actual         ) 
     OF Is:False            ; RetIsTrue =  CHOOSE( NOT Actual         )
   ! OF Is:Null             ; RetIsTrue =  CHOOSE(     Actual &= NULL )
   ! OF Is:NotNull          ; RetIsTrue =  CHOOSE( NOT Actual &= NULL )
   ELSE                     ; RetIsTrue =  Status:Inconclusive !<-- a misnomer, but it's as good as anything that's not TRUE or FALSE
   END   
   RETURN RetIsTrue

!==============================================================================
CwUnit_ctResult.Evaluate         PROCEDURE(*? LHS, STRING       Operator, ? RHS)!,BOOL
RetIsTrue BOOL
   CODE
   CASE Operator
     OF     Is:EqualTo            ; RetIsTrue = CHOOSE( LHS  = RHS                     )
     OF     Is:NotEqualTo         ; RetIsTrue = CHOOSE( LHS <> RHS                     )
     OF     Is:GreaterThan        ; RetIsTrue = CHOOSE( LHS >  RHS                     )
     OF     Is:GreaterThanOrEqual ; RetIsTrue = CHOOSE( LHS >= RHS                     )
     OF     Is:LessThan           ; RetIsTrue = CHOOSE( LHS <= RHS                     )
     OF     Is:LessThanOrEqual    ; RetIsTrue = CHOOSE( LHS <= RHS                     )
     OF String:StartsWith         ; RetIsTrue = CHOOSE( SUB(LHS, 1, LEN(RHS)) = RHS   ) ! Bigger  StartsWith Smaller
     OF String:Contains           ; RetIsTrue = CHOOSE( INSTRING(RHS, LHS, 1, 1)       ) ! Bigger  Contains   Smaller
     OF String:AppearsIn          ; RetIsTrue = CHOOSE( INSTRING(LHS, RHS, 1, 1)       ) ! Smaller AppearsIn  Bigger
     OF String:EndsWith           ; RetIsTrue = CHOOSE( SUB(LHS, -LEN(RHS), -1) = RHS ) ! Bigger  EndsWidth  Smaller
   ELSE                       ; RetIsTrue = Status:Inconclusive !<-- a misnomer, but it's as good as anything that's not TRUE or FALSE
   END   
   RETURN RetIsTrue

!==============================================================================
CwUnit_ctResult.GetOperatorType  PROCEDURE(STRING Operator)!,OperatorTypeEnum
RetType OperatorTypeEnum,AUTO
   CODE
   CASE Operator
     OF Is:EqualTo            
   OROF Is:NotEqualTo         
   OROF Is:GreaterThan        
   OROF Is:GreaterThanOrEqual 
   OROF Is:LessThan           
   OROF Is:LessThanOrEqual    
   OROF String:StartsWith         
   OROF String:Contains           
   OROF String:AppearsIn
   OROF String:EndsWith           ; RetType = OperatorType:Binary

     OF Is:True     
   OROF Is:False             
  !OROF Is:Null     
  !OROF Is:NotNull            
                              ; RetType = OperatorType:Unary

   ELSE                       ; RetType = OperatorType:Unknown
   END
   RETURN RetType



!==============================================================================
CwUnit_ctResult.PassesWhen       PROCEDURE(? LHS   , STRING       Operator, <? RHS>, <? Passed>, <? Failed> )!,StatusEnum,PROC
RetStatus  StatusEnum,AUTO
   CODE
   CASE SELF.GetOperatorType(Operator)
     OF OperatorType:Binary  ; IF OMITTED(RHS)
                                   RetStatus = Status:Inconclusive
                                   SELF.Inconclusive('Missing 2nd Argument  LHS['& LHS &'] Operator['& Operator &'] Failed['& Failed &']')
                               ELSE
                                    RetStatus = CHOOSE( SELF.Evaluate(LHS, Operator, RHS) = TRUE, Status:Pass, Status:Fail) !Since Operator is confirmed, assume .Evaluate will only return TRUE/FALSE
                                    SELF.PassFail(  CHOOSE( RetStatus = Status:Pass) , LHS, Operator, RHS ,Passed, Failed)    
                               END

     OF OperatorType:Unary   ; IF ~OMITTED(RHS) 
                                   RetStatus = Status:Inconclusive
                                   SELF.Inconclusive('Extra Argument in Expression( ['& LHS &'] ['& Operator &'] ['& RHS &'] Failed['& Failed &']')     
                               ELSE
                                    RetStatus = CHOOSE( SELF.Evaluate(LHS, Operator) = TRUE, Status:Pass, Status:Fail)  !Since Operator is confirmed, assume .Evaluate will only return TRUE/FALSE
                                    SELF.PassFail(  CHOOSE( RetStatus = Status:Pass) , LHS, Operator,  ,Passed, Failed)     
                               END

     OF OperatorType:Unknown ; RetStatus = Status:Inconclusive
                               SELF.Inconclusive('Unknown Operator['& Operator &'] Failed['& Failed &']')
   END
   RETURN RetStatus



!==============================================================================
CwUnit_ctResult.FailsWhen       PROCEDURE(? LHS   , STRING       Operator, <? RHS>, <? Passed>, <? Failed> )!,StatusEnum,PROC
RetStatus  StatusEnum,AUTO
   CODE
   CASE SELF.GetOperatorType(Operator)
     OF OperatorType:Binary  ; IF OMITTED(RHS)
                                   RetStatus = Status:Inconclusive
                                   SELF.Inconclusive('Missing 2nd Argument  LHS['& LHS &'] Operator['& Operator &'] Failed['& Failed &']')

                               ELSE                                                      ! v--------- the differernce from .PassesWhen
                                    RetStatus = CHOOSE( SELF.Evaluate(LHS, Operator, RHS) <> TRUE, Status:Pass, Status:Fail) !Since Operator is confirmed, assume .Evaluate will only return TRUE/FALSE
                                    SELF.PassFail(  CHOOSE( RetStatus = Status:Pass) , LHS, Operator, RHS ,Passed, Failed)    
                               END

     OF OperatorType:Unary   ; IF ~OMITTED(RHS) 
                                   RetStatus = Status:Inconclusive
                                   SELF.Inconclusive('Extra Argument in Expression( ['& LHS &'] ['& Operator &'] ['& RHS &'] Failed['& Failed &']')     

                               ELSE                                                 ! v--------- the differernce from .PassesWhen
                                    RetStatus = CHOOSE( SELF.Evaluate(LHS, Operator) <> TRUE, Status:Pass, Status:Fail)  !Since Operator is confirmed, assume .Evaluate will only return TRUE/FALSE
                                    SELF.PassFail(  CHOOSE( RetStatus = Status:Pass) , LHS, Operator,  ,Passed, Failed)     
                               END

     OF OperatorType:Unknown ; RetStatus = Status:Inconclusive
                               SELF.Inconclusive('Unknown Operator['& Operator &'] Failed['& Failed &']')
   END
   RETURN RetStatus



!==============================================================================
CwUnit_ctResult.PassFail    PROCEDURE(BOOL TestPassed, ? LHS, STRING Operator, <? RHS>, <? Passed>, <? Failed> )
   CODE
   IF TestPassed
      IF Passed = ''
            SELF.Pass( SELF.DefaultOutput(LHS, Operator, RHS) )
      ELSE
            SELF.Pass( Passed )
      END
   ELSE
      IF Failed = ''
            SELF.Fail( SELF.DefaultOutput(LHS, Operator, RHS) )
      ELSE
            SELF.Fail( Failed )      
      END
   END

!==============================================================================
CwUnit_ctResult.Equal       PROCEDURE(? Expected, ? Actual, <? Passed>, <? Failed> )            
   CODE
   SELF.PassFail( CHOOSE(Actual = Expected), Expected, Is:EqualTo, Passed, Failed)

!==============================================================================
CwUnit_ctResult.NotEqual    PROCEDURE(? Expected, ? Actual, <? Passed>, <? Failed> )            
   CODE
   SELF.PassFail( CHOOSE(Actual <> Expected), Expected, Is:NotEqualTo, Passed, Failed)

!==============================================================================
CwUnit_ctResult.Greater          PROCEDURE( ? Actual, ? CompareTo, <? Passed>, <? Failed> ) !Pass when:  Actual >  CompareTo
   CODE
   SELF.PassFail( CHOOSE(Actual > CompareTo)  , Actual, Is:GreaterThan, CompareTo,   Passed, Failed)

!==============================================================================
CwUnit_ctResult.GreaterOrEqual   PROCEDURE( ? Actual, ? CompareTo, <? Passed>, <? Failed> ) !Pass when:  Actual >= CompareTo
   CODE
   SELF.PassFail( CHOOSE(Actual >= CompareTo)  , Actual, Is:GreaterThanOrEqual, CompareTo,   Passed, Failed)

!==============================================================================
CwUnit_ctResult.Less             PROCEDURE( ? Actual, ? CompareTo, <? Passed>, <? Failed> ) !Pass when:  Actual <  CompareTo
   CODE
   SELF.PassFail( CHOOSE(Actual < CompareTo)  , Actual, Is:LessThan, CompareTo,   Passed, Failed)
   
!==============================================================================
CwUnit_ctResult.LessOrEqual      PROCEDURE( ? Actual, ? CompareTo, <? Passed>, <? Failed> ) !Pass when:  Actual <= CompareTo
   CODE
   SELF.PassFail( CHOOSE(Actual <= CompareTo)  , Actual, Is:LessThanOrEqual, CompareTo,   Passed, Failed)

!==============================================================================
CwUnit_ctResult.IsTrue           PROCEDURE(            ? Actual, <? Passed>, <? Failed> )
DidTestPass BOOL,AUTO
   CODE
   IF Actual
      DidTestPass = TRUE
   ELSE
      DidTestPass = FALSE
   END
   SELF.PassFail(  DidTestPass,Actual, Is:True    ,     ,    Passed, Failed)   
!==============================================================================
CwUnit_ctResult.IsFalse          PROCEDURE(            ? Actual, <? Passed>, <? Failed> )
DidTestPass BOOL,AUTO
   CODE
   IF Actual
      DidTestPass = FALSE
   ELSE
      DidTestPass = TRUE
   END
   SELF.PassFail(  DidTestPass,Actual, Is:False    ,     ,    Passed, Failed)   





!==============================================================================
CwUnit_ctResult.StartsWith        PROCEDURE(STRING Bigger , STRING Smaller , <? Passed>, <? Failed> )
   CODE
   mod:ODS.Add('CwUnit_ctResult.StartsWith: Bigger['& Bigger &'] StartsWith Smaller['& Smaller &'] SUB(Bigger, 1, LEN(Smaller)['& SUB(Bigger, 1, LEN(Smaller)) &'] WillPass['& CHOOSE( SUB(Bigger, 1, LEN(Smaller)) = Smaller) &']')
   SELF.PassFail( CHOOSE( SUB(Bigger, 1, LEN(Smaller)) = Smaller) , Bigger, String:StartsWith, Smaller  ,   Passed, Failed)   


!==============================================================================
CwUnit_ctResult.Contains          PROCEDURE(STRING Bigger , STRING Smaller , <? Passed>, <? Failed> )
   CODE
   SELF.PassFail( CHOOSE( INSTRING(Smaller, Bigger, 1, 1) ), Bigger, String:Contains, Smaller ,   Passed, Failed)   

!==============================================================================
CwUnit_ctResult.AppearsIn         PROCEDURE(STRING Smaller, STRING Bigger , <? Passed>, <? Failed> )
   CODE   
   SELF.PassFail( CHOOSE( INSTRING(Smaller, Bigger, 1, 1) ), Smaller, String:AppearsIn, Bigger  ,   Passed, Failed)   

   
!==============================================================================
CwUnit_ctResult.EndsWith          PROCEDURE(STRING Bigger , STRING Smaller , <? Passed>, <? Failed> )
   CODE
   SELF.PassFail( CHOOSE( SUB(Bigger, -LEN(Smaller), -1) = Smaller ) , Bigger, String:EndsWith, Smaller  ,   Passed, Failed)   



!------- I have not figured out how to make these work ------
! !==============================================================================
!CwUnit_ctResult.IsNullToString   PROCEDURE(*? Object)!,STRING
!   CODE
!   RETURN CHOOSE( Object &= NULL, 'Null', 'ADDRESS('& ADDRESS(Object) &')' )
!==============================================================================
!CwUnit_ctResult.IsNull           PROCEDURE(           *? Object, <? Passed>, <? Failed> ) 
!   CODE
!   MOD:ODS.Add('ctOneResult - IsNull ['& CHOOSE( Object &= NULL, 'NULL','NON-NULL') &']')
!
!   SELF.PassFail( CHOOSE(     Object &= NULL) , Object, Is:Null   ,  ,   Passed, Failed)   
!
!!==============================================================================
!CwUnit_ctResult.IsNotNull        PROCEDURE(           *? Object, <? Passed>, <? Failed> )
!   CODE
!   MOD:ODS.Add('ctOneResult - IsNotNull ['& CHOOSE( Object &= NULL, 'NULL','NON-NULL') &']')
!   SELF.PassFail( CHOOSE( NOT Object &= NULL) , Object, Is:NotNull,  ,   Passed, Failed)   

