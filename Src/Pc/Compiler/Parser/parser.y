%namespace Microsoft.Pc.Parser
%using Microsoft.Pc.Domains;
%visibility internal
%YYSTYPE LexValue
%partial

%union {
	public string str;
}

%token INT BOOL ANY SEQ MAP ID
%token TYPE INCLUDE MAIN EVENT MACHINE MONITOR ASSUME
%token VAR START HOT COLD MODEL STATE FUN ACTION GROUP PUBLIC OBSERVES

%token ENTRY EXIT DEFER IGNORE GOTO ON DO PUSH AS WITH

%token IF WHILE THIS NEW RETURN ID POP ASSERT PRINT CALL RAISE SEND DEFAULT FRESH HALT NULL RECEIVE CASE
%token LPAREN RPAREN LCBRACE RCBRACE LBRACKET RBRACKET SIZEOF KEYS VALUES

%token TRUE FALSE

%token SPEC MODULE SENDS CREATES RECEIVES INTERFACE 
%token TEST REFINES SATISFIES IMPLEMENTATION SPECIFICATION HIDE
%token PO EVENTLIST

%token ASSIGN REMOVE INSERT
%token EQ NE LT GT LE GE IN
%left LAND LNOT LOR NONDET FAIRNONDET

%token DOT COLON COMMA
%left  SEMICOLON

%token INT BOOL STR

%left  PLUS MINUS
%left  DIV
%left  MUL 
%token ELSE

%token maxParseToken 
%token LEX_WHITE LEX_ERROR LEX_COMMENT

%%

Program
    : EOF
	| TopDeclList
	| AnnotationSet                { AddProgramAnnots(ToSpan(@1)); }
	| AnnotationSet TopDeclList    { AddProgramAnnots(ToSpan(@1)); }
	;

TopDeclList
    : TopDecl
	| TopDeclList TopDecl 
	;

TopDecl
    : IncludeDecl
	| TypeDefDecl
	| EventListDecl
	| PODecl
	| EventDecl
	| InterfaceDecl
	| ModuleDecl
	| TestDecl
	| ImplementationDecl
	| SpecificationDecl
	;

/******************* Annotations *******************/ 
AnnotationSet
    : LBRACKET RBRACKET                  { PushAnnotationSet(); }
	| LBRACKET AnnotationList RBRACKET   { PushAnnotationSet(); }
	;

AnnotationList
    : Annotation
	| AnnotationList COMMA Annotation
	;

Annotation
    : ID ASSIGN NULL    { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.NULL, ToSpan(@1), ToSpan(@3));  }
	| ID ASSIGN TRUE    { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.TRUE, ToSpan(@1), ToSpan(@3));  }
	| ID ASSIGN FALSE   { AddAnnotUsrCnstVal($1.str, P_Root.UserCnstKind.FALSE, ToSpan(@1), ToSpan(@3)); }
	| ID ASSIGN ID      { AddAnnotStringVal($1.str, $3.str, ToSpan(@1), ToSpan(@3));                     }
	| ID ASSIGN INT     { AddAnnotIntVal($1.str, $3.str, ToSpan(@1), ToSpan(@3));                        }
	;

/******************* Type Declarations **********************/
TypeDefDecl
    : TYPE ID SEMICOLON 			  { AddEmptyTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	| TYPE ID ASSIGN Type SEMICOLON   { AddTypeDef($2.str, ToSpan(@2), ToSpan(@1)); }
	;

/******************* EventList and ModuleList Declarations **********************/
EventListDecl
	: EVENTLIST ID ASSIGN NonDefaultEventList SEMICOLON   { AddNameEventList($2.str, ToSpan(@2), ToSpan(@1)); }
	;

/******************* Partial Order Over Events ********************************/
PODecl
	: PO ID GT NonDefaultEventList SEMICOLON		  { AddEventsPO($2.str, ToSpan(@2), ToSpan(@1)); }
	;

/******************* Include Declarations *******************/ 
IncludeDecl
	: INCLUDE STR { parseIncludedFileNames.Add($2.str.Substring(1,$2.str.Length-2)); }
	;

/****************** Interface Declarations ******************/
InterfaceDecl
	: INTERFACE ID NonDefaultEventList SEMICOLON				{ AddInterfaceType($2.str, ToSpan(@2), ToSpan(@2)); } 
	;

/***************** Module Declarations *********************/
ModuleDecl
	: SPEC MODULE ID SendsList CreatesList LCBRACE ModuleBody RCBRACE		{ AddModule(P_Root.UserCnstKind.SPEC, $3.str, ToSpan(@3), ToSpan(@1)); }
	| MODULE ID SendsList CreatesList LCBRACE ModuleBody RCBRACE			{ AddModule(P_Root.UserCnstKind.IMPL, $2.str, ToSpan(@2), ToSpan(@1)); }
	;

ModuleBody
	: ModuleBodyItem
	| ModuleBodyItem ModuleBody 
	;

ModuleBodyItem
	: MachineDecl
	| StaticFunDecl
	| MonitorDecl
	;

SendsList
	: SENDS NonDefaultEventList			{ crntSendsList.AddRange(crntEventList); crntEventList.Clear();}
	|
	;

CreatesList
	: CREATES InterfaceList
	|
	;

InterfaceList
	: ID						{ AddToInterfaceList($1.str, ToSpan(@1));}
	| ID COMMA InterfaceList	{ AddToInterfaceList($1.str, ToSpan(@1));}
	;
		
/***************** Monitor Declaration *********************/
MonitorDecl
	: MONITOR ID ObservesList MachAnnotOrNone LCBRACE MachineBody RCBRACE			   { AddMachine(P_Root.UserCnstKind.MONITOR, $2.str, ToSpan(@2), ToSpan(@1)); }
	;

ObservesList
	: OBSERVES NonDefaultEventList { crntObservesList.AddRange(crntEventList); crntEventList.Clear(); }
	;


/******************* Event Declarations *******************/ 
EventDecl
	: EVENT ID EvCardOrNone EvTypeOrNone EventAnnotOrNone SEMICOLON { AddEvent($2.str, ToSpan(@2), ToSpan(@1)); }
	;

EvCardOrNone
	: ASSERT INT									{ SetEventCard($2.str, true,  ToSpan(@1)); }
	| ASSUME INT									{ SetEventCard($2.str, false, ToSpan(@1)); }
	|												{ }
	;

EvTypeOrNone
	: COLON Type									{ SetEventType(ToSpan(@1));                }
	|												{ }
	;

EventAnnotOrNone
    : AnnotationSet                                 { AddEventAnnots(ToSpan(@1));              }
	|
	;

/******************  TEST Declarations **********************/
TestDecl
	: TEST ID COLON ModuleList REFINES ModuleList SEMICOLON			{ AddRefinesTest($2.str, ToSpan(@2), ToSpan(@1));   }	
	| TEST ID COLON ModuleList SATISFIES MonitorList SEMICOLON		{ AddSatisfiesTest($2.str, ToSpan(@2), ToSpan(@1));  }
	| TEST ID COLON ModuleList SEMICOLON							{ AddSatisfiesTest($2.str, ToSpan(@2), ToSpan(@1)); }
	;

MonitorList
	: ID				{ AddToMonitorList($1.str, ToSpan(@1)); }
	| ID MonitorList    { AddToMonitorList($1.str, ToSpan(@1)); }
	;
Hide
	: HIDE NonDefaultEventList IN LPAREN ModuleList RPAREN	{ PushHideModule(ToSpan(@1)); }
	;

Module
	: Hide
	| ID															{ PushModule($1.str, ToSpan(@1)); }		
	;

ModuleList
	: Module														{ PushModuleList(ToSpan(@1), true); }
	| Module COMMA ModuleList										{ PushModuleList(ToSpan(@1), false);}
	;

/***************** Implementation and Specification **********/
ImplementationDecl
	:	IMPLEMENTATION ModuleList SEMICOLON								{ AddImplementationList(ToSpan(@1)); }
	;

SpecificationDecl
	:	SPECIFICATION ModuleList SEMICOLON									{ AddSpecificationList(ToSpan(@1));	 }
	;

/******************* Machine Declarations *******************/
MachineDecl
	: IsMain MACHINE ID Receives MachCardOrNone MachAnnotOrNone LCBRACE MachineBody RCBRACE { AddMachine(P_Root.UserCnstKind.REAL, $3.str, ToSpan(@3), ToSpan(@1));    }
	| IsMain MODEL ID Receives MachCardOrNone MachAnnotOrNone LCBRACE MachineBody RCBRACE   { AddMachine(P_Root.UserCnstKind.MODEL, $3.str, ToSpan(@3), ToSpan(@1));   }
	;
	

Receives
	: RECEIVES NonDefaultEventList           { crntReceivesList.AddRange(crntEventList); crntEventList.Clear(); }
	|
	;

IsMain
	: MAIN											{ SetMachineIsMain(ToSpan(@1)); }
	|												{ }
	;

MachCardOrNone
	: ASSERT INT									{ SetMachineCard($2.str, true,  ToSpan(@1)); }
	| ASSUME INT									{ SetMachineCard($2.str, false, ToSpan(@1)); }
	|												{ }
	;

MachAnnotOrNone
    : AnnotationSet                                 { AddMachineAnnots(ToSpan(@1));              }
	|
	;

/******************* Machine Bodies *******************/
MachineBody
	: MachineBodyItem												
	| MachineBody MachineBodyItem 					
	;

MachineBodyItem
	: VarDecl
	| FunDecl
	| StateDecl
	| Group
	;

/******************* Variable Declarations *******************/
VarDecl
	: VAR VarList COLON Type SEMICOLON	             { AddVarDecls(false, ToSpan(@1)); }
	| VAR VarList COLON Type AnnotationSet SEMICOLON { AddVarDecls(true,  ToSpan(@5)); }
	;

VarList
	: ID                  { AddVarDecl($1.str, ToSpan(@1)); }									
	| ID COMMA VarList    { AddVarDecl($1.str, ToSpan(@1)); }
	;

LocalVarDecl
	: VAR LocalVarList COLON Type SEMICOLON            { localVarStack.CompleteCrntLocalVarList(); }
	; 

LocalVarDeclList
	: LocalVarDecl LocalVarDeclList
	|
	; 

LocalVarList
	: ID					   { localVarStack.AddLocalVar($1.str, ToSpan(@1)); }									
	| LocalVarList COMMA ID    { localVarStack.AddLocalVar($3.str, ToSpan(@3)); }
	;

PayloadVarDeclOrNone
	: LPAREN ID COLON Type RPAREN { localVarStack.AddPayloadVar($2.str, ToSpan(@2)); localVarStack.Push(); }
	|                             { localVarStack.AddPayloadVar(); localVarStack.Push(); }
	;

/******************* Function Declarations *******************/
IsPublic 
	: PUBLIC { isStaticFun = true; isPublic = true;}
	|		 { isStaticFun = true; }
	;

StaticFunDecl
	: IsPublic IsModel FUN ID ParamsOrNone RetTypeOrNone FunAnnotOrNone StmtBlock { AddFunction($4.str, ToSpan(@4), ToSpan(@1), true); }
	;

FunDecl
	: IsModel FUN ID ParamsOrNone RetTypeOrNone FunAnnotOrNone StmtBlock { AddFunction($3.str, ToSpan(@3), ToSpan(@1), false); }
	;

IsModel
	: MODEL											{ SetFunKind(P_Root.UserCnstKind.MODEL, ToSpan(@1)); }
	|												{ }
	;

FunAnnotOrNone
    : AnnotationSet { AddFunAnnots(ToSpan(@1)); }
	|
	;

ParamsOrNone
    : LPAREN RPAREN
	| LPAREN NmdTupTypeList RPAREN                  { SetFunParams(ToSpan(@1)); }
	;

RetTypeOrNone
    : COLON Type                                    { SetFunReturn(ToSpan(@1)); }
	| 
	;

/*******************       Group        *******************/
Group
    : GroupName LCBRACE RCBRACE             { AddGroup(); }      
    | GroupName LCBRACE GroupBody RCBRACE   { AddGroup(); }
	;

GroupBody
    : GroupItem
	| GroupBody GroupItem 
	;

GroupItem
    : StateDecl
	| Group
	;

GroupName
    : GROUP ID	{ PushGroup($2.str, ToSpan(@2), ToSpan(@1)); }
	;

/******************* State Declarations *******************/
StateDecl
	: IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE RCBRACE                  { AddState($3.str, false, ToSpan(@3), ToSpan(@1)); }
	| IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE StateBody RCBRACE        { AddState($3.str, false, ToSpan(@3), ToSpan(@1)); }	  
	| START IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE RCBRACE            { AddState($4.str, true,  ToSpan(@4), ToSpan(@1)); }
	| START IsHotOrColdOrNone STATE ID StateAnnotOrNone LCBRACE StateBody RCBRACE  { AddState($4.str, true,  ToSpan(@4), ToSpan(@1)); }	  
	;

IsHotOrColdOrNone
	: HOT        { SetStateIsHot(ToSpan(@1)); }
	| COLD		 { SetStateIsCold(ToSpan(@1)); }
	|
	;

StateAnnotOrNone
    : AnnotationSet { AddStateAnnots(ToSpan(@1)); }
	|
	;

StateBody
	: StateBodyItem
	| StateBodyItem StateBody 
	;

StateBodyItem
	: ENTRY PayloadVarDeclOrNone StmtBlock									{ SetStateEntry(true);                                  }	
	| ENTRY ID SEMICOLON													{ SetStateEntry(false, $2.str, ToSpan(@2)); }			
	| EXIT StmtBlock														{ localVarStack.AddPayloadVar(); localVarStack.Push(); SetStateExit(true);                                   }
	| EXIT ID SEMICOLON														{ SetStateExit(false, $2.str, ToSpan(@2));                                 }
	| DEFER NonDefaultEventList TrigAnnotOrNone SEMICOLON					{ AddDefersOrIgnores(true,  ToSpan(@1));            }		
	| IGNORE NonDefaultEventList TrigAnnotOrNone SEMICOLON					{ AddDefersOrIgnores(false, ToSpan(@1));            }
	| OnEventList DO ID TrigAnnotOrNone SEMICOLON							{ AddDoNamedAction($3.str, ToSpan(@3), ToSpan(@1)); }
	| OnEventList DO TrigAnnotOrNone PayloadVarDeclOrNone StmtBlock SEMICOLON					{ AddDoAnonyAction(ToSpan(@1)); }
	| OnEventList PUSH StateTarget TrigAnnotOrNone SEMICOLON				{ AddTransition(true, ToSpan(@1));           }
 	| OnEventList GOTO StateTarget TrigAnnotOrNone SEMICOLON				{ AddTransition(false, ToSpan(@1));          } 
	| OnEventList GOTO StateTarget TrigAnnotOrNone WITH PayloadVarDeclOrNone StmtBlock SEMICOLON { AddTransitionWithAction(true, "", ToSpan(@1), ToSpan(@1));           }
	| OnEventList GOTO StateTarget TrigAnnotOrNone WITH ID SEMICOLON		{ AddTransitionWithAction(false, $6.str, ToSpan(@6), ToSpan(@1));           }
	;

OnEventList
	: ON EventList				{ onEventList = new List<P_Root.EventLabel>(crntEventList); crntEventList.Clear(); }
	;


NonDefaultEventList
	: NonDefaultEventId
	| NonDefaultEventList COMMA NonDefaultEventId 
	;

EventList
	: EventId
	| EventList COMMA EventId
	;

EventId
	: ID        { AddToEventList($1.str, ToSpan(@1));                      }
	| HALT      { AddToEventList(P_Root.UserCnstKind.HALT, ToSpan(@1));    }
	| NULL      { AddToEventList(P_Root.UserCnstKind.NULL, ToSpan(@1)); }
	;

NonDefaultEventId
	: ID        { AddToEventList($1.str, ToSpan(@1));                      }
	| HALT      { AddToEventList(P_Root.UserCnstKind.HALT, ToSpan(@1));    }
	;

TrigAnnotOrNone
    : AnnotationSet  { SetTrigAnnotated(ToSpan(@1)); }
	|
	;

/******************* Type Expressions *******************/

Type
	: NULL                                  { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.NULL,    ToSpan(@1))); }
	| BOOL                                  { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.BOOL,    ToSpan(@1))); }
	| INT                                   { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.INT,     ToSpan(@1))); }
	| EVENT                                 { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.EVENT,   ToSpan(@1))); }
	| MACHINE                               { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.REAL,    ToSpan(@1))); }						
	| ANY                                   { PushTypeExpr(MkBaseType(P_Root.UserCnstKind.ANY,     ToSpan(@1))); }
	| ID                                    { PushNameType($1.str, ToSpan(@1)); }
	| SEQ LBRACKET Type RBRACKET            { PushSeqType(ToSpan(@1)); }
	| MAP LBRACKET Type COMMA Type RBRACKET { PushMapType(ToSpan(@1)); }
	| LPAREN TupTypeList RPAREN	
	| LPAREN NmdTupTypeList RPAREN	
	;

TupTypeList
	: Type						{ PushTupType(ToSpan(@1), true);  }
	| Type COMMA TupTypeList	{ PushTupType(ToSpan(@1), false); }
	;

NmdTupTypeList
	: ID COLON Type						  { PushNmdTupType($1.str, ToSpan(@1), true);  }			
	| ID COLON Type COMMA NmdTupTypeList  { PushNmdTupType($1.str, ToSpan(@1), false); }	
	;

/******************* Statements *******************/

Stmt
	: SEMICOLON                                               { PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1));      }
	| LCBRACE RCBRACE                                         { PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1));      }
	| POP SEMICOLON                                           { PushNulStmt(P_Root.UserCnstKind.POP,   ToSpan(@1));      }
	| LCBRACE StmtList RCBRACE                                { }
	| ASSERT Exp SEMICOLON                                    { PushAssert(ToSpan(@1));                                  }
	| ASSERT Exp COMMA STR SEMICOLON                          { PushAssert($4.str.Substring(1,$4.str.Length-2), ToSpan(@4), ToSpan(@1)); }
	| PRINT STR SEMICOLON                                     { PushPrint($2.str.Substring(1,$2.str.Length-2), ToSpan(@2), ToSpan(@1));  }
	| RETURN SEMICOLON                                        { PushReturn(false, ToSpan(@1));                           }
	| RETURN Exp SEMICOLON                                    { PushReturn(true, ToSpan(@1));                            }
	| Exp ASSIGN Exp SEMICOLON                                { PushBinStmt(P_Root.UserCnstKind.ASSIGN, ToSpan(@1));     }
	| Exp REMOVE Exp SEMICOLON                                { PushBinStmt(P_Root.UserCnstKind.REMOVE, ToSpan(@1));     }
	| Exp INSERT Exp SEMICOLON								  { PushBinStmt(P_Root.UserCnstKind.INSERT, ToSpan(@1));	 }
	| WHILE LPAREN Exp RPAREN Stmt                            { PushWhile(ToSpan(@1));                                   }
	| IF LPAREN Exp RPAREN Stmt ELSE Stmt %prec ELSE          { PushIte(true, ToSpan(@1));                               }					
	| IF LPAREN Exp RPAREN Stmt		                          { PushIte(false, ToSpan(@1));                              }
	| NEW ID LPAREN RPAREN SEMICOLON						  { PushNewStmt($2.str, ToSpan(@2), false, ToSpan(@1)); }
	| NEW ID LPAREN SingleExprArgList RPAREN SEMICOLON 		  { PushNewStmt($2.str, ToSpan(@2), true, ToSpan(@1)); }
	| ID LPAREN RPAREN SEMICOLON                              { PushFunStmt($1.str, false, ToSpan(@1));                  }
	| ID LPAREN ExprArgList RPAREN SEMICOLON                  { PushFunStmt($1.str, true,  ToSpan(@1));                  }
	| ID COLON COLON ID LPAREN RPAREN SEMICOLON               { PushStaticFunStmt($1.str, ToSpan(@1), $4.str, ToSpan(@4), false, ToSpan(@1)); }
	| ID COLON COLON ID LPAREN ExprArgList RPAREN SEMICOLON   { PushStaticFunStmt($1.str, ToSpan(@1), $4.str, ToSpan(@4), true,  ToSpan(@1)); }						
	| RAISE Exp SEMICOLON                                     { PushRaise(false, ToSpan(@1));                            }
	| RAISE Exp COMMA SingleExprArgList SEMICOLON             { PushRaise(true,  ToSpan(@1));                            }
	| SEND Exp COMMA Exp SEMICOLON                            { PushSend(false, ToSpan(@1));                             }
	| SEND Exp COMMA Exp COMMA SingleExprArgList SEMICOLON    { PushSend(true,  ToSpan(@1));                             }
	| MONITOR Exp SEMICOLON									  { PushMonitor(false, $2.str, ToSpan(@2), ToSpan(@1));      }
	| MONITOR Exp COMMA SingleExprArgList SEMICOLON           { PushMonitor(true, $2.str, ToSpan(@2), ToSpan(@1));       }
	| ReceiveStmt LCBRACE CaseList RCBRACE					  { PushReceive(ToSpan(@1)); }
	;

ReceiveStmt
 : RECEIVE              { localVarStack.PushCasesList(); }
 ;

Case 
	: CaseEventList PayloadVarDeclOrNone StmtBlock 		{ AddCaseAnonyAction(ToSpan(@3)); }
	;

CaseEventList
	: CASE EventList COLON
	;

CaseList	
	: Case							
	| CaseList Case
	;
	 
StmtBlock
	: LCBRACE LocalVarDeclList RCBRACE                                         { PushNulStmt(P_Root.UserCnstKind.SKIP,  ToSpan(@1));      }    
    | LCBRACE LocalVarDeclList StmtList RCBRACE
	;

StmtList
	: Stmt
	| Stmt StmtList    { PushSeq(); }													
	;

StateTarget
    : ID                  { QualifyStateTarget($1.str, ToSpan(@1)); }
	| StateTarget DOT ID   { QualifyStateTarget($3.str, ToSpan(@3)); }
	;

/******************* Value Expressions *******************/

Exp
  : Exp_8
  ;

Exp_8 
	: Exp_8 LOR Exp_7	{ PushBinExpr(P_Root.UserCnstKind.OR, ToSpan(@2)); }
	| Exp_7
	;

Exp_7
	: Exp_7 LAND Exp_6	{ PushBinExpr(P_Root.UserCnstKind.AND, ToSpan(@2)); }
	| Exp_6
	;

Exp_6 
	: Exp_5 EQ Exp_5 { PushBinExpr(P_Root.UserCnstKind.EQ,  ToSpan(@2)); }
	| Exp_5 NE Exp_5 { PushBinExpr(P_Root.UserCnstKind.NEQ, ToSpan(@2)); }
	| Exp_5
	;

Exp_5 
	: Exp_4 LT Exp_4 { PushBinExpr(P_Root.UserCnstKind.LT, ToSpan(@2)); }
	| Exp_4 LE Exp_4 { PushBinExpr(P_Root.UserCnstKind.LE, ToSpan(@2)); }
	| Exp_4 GT Exp_4 { PushBinExpr(P_Root.UserCnstKind.GT, ToSpan(@2)); }
	| Exp_4 GE Exp_4 { PushBinExpr(P_Root.UserCnstKind.GE, ToSpan(@2)); }
	| Exp_4 IN Exp_4 { PushBinExpr(P_Root.UserCnstKind.IN, ToSpan(@2)); }
	| Exp_4
	;

Exp_4 
	: Exp_4 AS Type { PushCast(ToSpan(@2)); }	
	| Exp_3
	;

Exp_3 
	: Exp_3 PLUS Exp_2   { PushBinExpr(P_Root.UserCnstKind.ADD, ToSpan(@2)); }	
	| Exp_3 MINUS Exp_2  { PushBinExpr(P_Root.UserCnstKind.SUB, ToSpan(@2)); }
	| Exp_2
	;

Exp_2 
	: Exp_2 MUL Exp_1  { PushBinExpr(P_Root.UserCnstKind.MUL,    ToSpan(@2)); }	
	| Exp_2 DIV Exp_1  { PushBinExpr(P_Root.UserCnstKind.INTDIV, ToSpan(@2)); }
	| Exp_1
	;

Exp_1 
	: MINUS Exp_0 { PushUnExpr(P_Root.UserCnstKind.NEG, ToSpan(@1)); }
	| LNOT  Exp_0 { PushUnExpr(P_Root.UserCnstKind.NOT, ToSpan(@1)); }
	| Exp_0
	;

Exp_0 
    : TRUE                                   { PushNulExpr(P_Root.UserCnstKind.TRUE,       ToSpan(@1)); }
    | FALSE                                  { PushNulExpr(P_Root.UserCnstKind.FALSE,      ToSpan(@1)); }
    | THIS                                   { PushNulExpr(P_Root.UserCnstKind.THIS,       ToSpan(@1)); }
    | NONDET                                 { PushNulExpr(P_Root.UserCnstKind.NONDET,     ToSpan(@1)); }
    | FAIRNONDET                             { PushNulExpr(P_Root.UserCnstKind.FAIRNONDET, ToSpan(@1)); }
    | NULL                                   { PushNulExpr(P_Root.UserCnstKind.NULL,       ToSpan(@1)); }
    | HALT                                   { PushNulExpr(P_Root.UserCnstKind.HALT,       ToSpan(@1)); }
	| INT                                    { PushIntExpr($1.str,  ToSpan(@1));                        }
    | ID                                     { PushName($1.str,     ToSpan(@1));                        }         
	| Exp_0 DOT ID                           { PushField($3.str,    ToSpan(@3));                        }   
	| Exp_0 DOT INT                          { PushFieldInt($3.str, ToSpan(@3));                        }   
	| Exp_0 LBRACKET Exp RBRACKET            { PushBinExpr(P_Root.UserCnstKind.IDX,        ToSpan(@2)); }
	| LPAREN Exp RPAREN                      { }
    | KEYS LPAREN Exp RPAREN                 { PushUnExpr(P_Root.UserCnstKind.KEYS,   ToSpan(@1));      }
    | VALUES  LPAREN Exp RPAREN              { PushUnExpr(P_Root.UserCnstKind.VALUES, ToSpan(@1));      }
    | SIZEOF  LPAREN Exp RPAREN              { PushUnExpr(P_Root.UserCnstKind.SIZEOF, ToSpan(@1));      }
    | DEFAULT LPAREN Type RPAREN             { PushDefaultExpr(ToSpan(@1));                             }
	| NEW ID LPAREN RPAREN					 { PushNewExpr($2.str, ToSpan(@2), false, ToSpan(@1)); }
	| NEW ID LPAREN SingleExprArgList RPAREN { PushNewExpr($2.str, ToSpan(@2), true, ToSpan(@1)); }
	| FRESH LPAREN ID RPAREN                 { PushFreshExpr($3.str, ToSpan(@3), ToSpan(@1));           }
	| LPAREN Exp COMMA             RPAREN    { PushTupleExpr(true);                                     }
	| LPAREN Exp COMMA ExprArgList RPAREN    { PushTupleExpr(false);                                    }
	| ID LPAREN RPAREN                       { PushFunExpr($1.str, false, ToSpan(@1));                  }
	| ID LPAREN ExprArgList RPAREN           { PushFunExpr($1.str, true, ToSpan(@1));                   }
	| ID COLON COLON ID LPAREN RPAREN                { PushStaticFunExpr($1.str, ToSpan(@1), $4.str, ToSpan(@4), false, ToSpan(@1));                  }
	| ID COLON COLON ID LPAREN ExprArgList RPAREN    { PushStaticFunExpr($1.str, ToSpan(@1), $4.str, ToSpan(@4), true, ToSpan(@1));                   }
	| LPAREN ID ASSIGN Exp COMMA RPAREN      { PushNmdTupleExpr($2.str, ToSpan(@2), true);              }
	| LPAREN ID ASSIGN Exp COMMA 
	  NmdExprArgList       RPAREN            { PushNmdTupleExpr($2.str, ToSpan(@2), false);             }
	;

// An arg list that can be a single expr, or an exprs
SingleExprArgList
	: Exp					      { MoveValToExprs(false); }
	| Exp COMMA SingleExprArgList { PushExprs();           }
	;

// An arg list that is always packed into an exprs.
ExprArgList
	: Exp					{ MoveValToExprs(true);  }
	| Exp COMMA ExprArgList { PushExprs();           }
	;

// A named arg list that is always packed into named exprs.
NmdExprArgList
	: ID ASSIGN Exp		                 { MoveValToNmdExprs($1.str, ToSpan(@1));  }
	| ID ASSIGN Exp COMMA NmdExprArgList { PushNmdExprs($1.str, ToSpan(@1));       }
	;

%%