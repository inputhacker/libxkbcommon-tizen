/************************************************************
 Copyright (c) 1994 by Silicon Graphics Computer Systems, Inc.

 Permission to use, copy, modify, and distribute this
 software and its documentation for any purpose and without
 fee is hereby granted, provided that the above copyright
 notice appear in all copies and that both that copyright
 notice and this permission notice appear in supporting
 documentation, and that the name of Silicon Graphics not be
 used in advertising or publicity pertaining to distribution
 of the software without specific prior written permission.
 Silicon Graphics makes no representation about the suitability
 of this software for any purpose. It is provided "as is"
 without any express or implied warranty.

 SILICON GRAPHICS DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
 SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL SILICON
 GRAPHICS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
 DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION  WITH
 THE USE OR PERFORMANCE OF THIS SOFTWARE.

 ********************************************************/

%{
#include "xkbcomp-priv.h"
#include "parseutils.h"

#pragma GCC diagnostic ignored "-Wredundant-decls"

extern int yylex(union YYSTYPE *val, struct YYLTYPE *loc, void *scanner);

static void
yyerror(struct YYLTYPE *loc, struct parser_param *param, const char *msg)
{
    scanner_error(loc, param->scanner, msg);
}

#define scanner param->scanner
%}

%define         api.pure
%locations
%lex-param      { void *scanner }
%parse-param    { struct parser_param *param }

%token
        END_OF_FILE     0
        ERROR_TOK       255
        XKB_KEYMAP      1
        XKB_KEYCODES    2
        XKB_TYPES       3
        XKB_SYMBOLS     4
        XKB_COMPATMAP   5
        XKB_GEOMETRY    6
        XKB_SEMANTICS   7
        XKB_LAYOUT      8
        INCLUDE         10
        OVERRIDE        11
        AUGMENT         12
        REPLACE         13
        ALTERNATE       14
        VIRTUAL_MODS    20
        TYPE            21
        INTERPRET       22
        ACTION_TOK      23
        KEY             24
        ALIAS           25
        GROUP           26
        MODIFIER_MAP    27
        INDICATOR       28
        SHAPE           29
        KEYS            30
        ROW             31
        SECTION         32
        OVERLAY         33
        TEXT            34
        OUTLINE         35
        SOLID           36
        LOGO            37
        VIRTUAL         38
        EQUALS          40
        PLUS            41
        MINUS           42
        DIVIDE          43
        TIMES           44
        OBRACE          45
        CBRACE          46
        OPAREN          47
        CPAREN          48
        OBRACKET        49
        CBRACKET        50
        DOT             51
        COMMA           52
        SEMI            53
        EXCLAM          54
        INVERT          55
        STRING          60
        INTEGER         61
        FLOAT           62
        IDENT           63
        KEYNAME         64
        PARTIAL         70
        DEFAULT         71
        HIDDEN          72
        ALPHANUMERIC_KEYS       73
        MODIFIER_KEYS           74
        KEYPAD_KEYS             75
        FUNCTION_KEYS           76
        ALTERNATE_GROUP         77

%right  EQUALS
%left   PLUS MINUS
%left   TIMES DIVIDE
%left   EXCLAM INVERT
%left   OPAREN

%start  XkbFile

%union  {
        int              ival;
        unsigned         uval;
        int64_t          num;
        enum xkb_file_type file_type;
        char            *str;
        char            keyName[XkbKeyNameLength];
        xkb_atom_t      sval;
        enum merge_mode merge;
        ParseCommon     *any;
        ExprDef         *expr;
        VarDef          *var;
        VModDef         *vmod;
        InterpDef       *interp;
        KeyTypeDef      *keyType;
        SymbolsDef      *syms;
        ModMapDef       *modMask;
        GroupCompatDef  *groupCompat;
        IndicatorMapDef *ledMap;
        IndicatorNameDef *ledName;
        KeycodeDef      *keyCode;
        KeyAliasDef     *keyAlias;
        void            *geom;
        XkbFile         *file;
}

%type <num>     INTEGER FLOAT
%type <str>     IDENT STRING
%type <keyName> KEYNAME KeyName
%type <ival>    Number Integer Float SignedNumber
%type <merge>   MergeMode OptMergeMode
%type <file_type> XkbCompositeType FileType
%type <uval>    DoodadType Flag Flags OptFlags KeyCode
%type <str>     MapName OptMapName KeySym
%type <sval>    FieldSpec Ident Element String
%type <any>     DeclList Decl
%type <expr>    OptExprList ExprList Expr Term Lhs Terminal ArrayInit KeySyms
%type <expr>    OptKeySymList KeySymList Action ActionList Coord CoordList
%type <var>     VarDecl VarDeclList SymbolsBody SymbolsVarDecl
%type <vmod>    VModDecl VModDefList VModDef
%type <interp>  InterpretDecl InterpretMatch
%type <keyType> KeyTypeDecl
%type <syms>    SymbolsDecl
%type <modMask> ModMapDecl
%type <groupCompat> GroupCompatDecl
%type <ledMap>  IndicatorMapDecl
%type <ledName> IndicatorNameDecl
%type <keyCode> KeyNameDecl
%type <keyAlias> KeyAliasDecl
%type <geom>    ShapeDecl SectionDecl SectionBody SectionBodyItem RowBody RowBodyItem
%type <geom>    Keys Key OverlayDecl OverlayKeyList OverlayKey OutlineList OutlineInList
%type <geom>    DoodadDecl
%type <file>    XkbFile XkbMapConfigList XkbMapConfig XkbConfig
%type <file>    XkbCompositeMap XkbCompMapList

%%

XkbFile         :       XkbCompMapList
                        { $$ = param->rtrn = $1; }
                |       XkbMapConfigList
                        { $$ = param->rtrn = $1; }
                |       XkbConfig
                        { $$ = param->rtrn = $1; }
                ;

XkbCompMapList  :       XkbCompMapList XkbCompositeMap
                        { $$ = (XkbFile *)AppendStmt(&$1->common, &$2->common); }
                |       XkbCompositeMap
                        { $$ = $1; }
                ;

XkbCompositeMap :       OptFlags XkbCompositeType OptMapName OBRACE
                            XkbMapConfigList
                        CBRACE SEMI
                        { $$ = CreateXKBFile(param->ctx, $2, $3, &$5->common, $1); }
                ;

XkbCompositeType:       XKB_KEYMAP      { $$ = FILE_TYPE_KEYMAP; }
                |       XKB_SEMANTICS   { $$ = FILE_TYPE_KEYMAP; }
                |       XKB_LAYOUT      { $$ = FILE_TYPE_KEYMAP; }
                ;

XkbMapConfigList :      XkbMapConfigList XkbMapConfig
                        {
                            if (!$2)
                                $$ = $1;
                            else
                                $$ = (XkbFile *)AppendStmt(&$1->common, &$2->common);
                        }
                |       XkbMapConfig
                        { $$ = $1; }
                ;

XkbMapConfig    :       OptFlags FileType OptMapName OBRACE
                            DeclList
                        CBRACE SEMI
                        {
                            if ($2 == FILE_TYPE_GEOMETRY) {
                                free($3);
                                FreeStmt($5);
                                $$ = NULL;
                            }
                            else {
                                $$ = CreateXKBFile(param->ctx, $2, $3, $5, $1);
                            }
                        }
                ;

XkbConfig       :       OptFlags FileType OptMapName DeclList
                        {
                            if ($2 == FILE_TYPE_GEOMETRY) {
                                free($3);
                                FreeStmt($4);
                                $$ = NULL;
                            }
                            else {
                                $$ = CreateXKBFile(param->ctx, $2, $3, $4, $1);
                            }
                        }
                ;


FileType        :       XKB_KEYCODES            { $$ = FILE_TYPE_KEYCODES; }
                |       XKB_TYPES               { $$ = FILE_TYPE_TYPES; }
                |       XKB_COMPATMAP           { $$ = FILE_TYPE_COMPAT; }
                |       XKB_SYMBOLS             { $$ = FILE_TYPE_SYMBOLS; }
                |       XKB_GEOMETRY            { $$ = FILE_TYPE_GEOMETRY; }
                ;

OptFlags        :       Flags                   { $$ = $1; }
                |                               { $$ = 0; }
                ;

Flags           :       Flags Flag              { $$ = ($1 | $2); }
                |       Flag                    { $$ = $1; }
                ;

Flag            :       PARTIAL                 { $$ = XkbLC_Partial; }
                |       DEFAULT                 { $$ = XkbLC_Default; }
                |       HIDDEN                  { $$ = XkbLC_Hidden; }
                |       ALPHANUMERIC_KEYS       { $$ = XkbLC_AlphanumericKeys; }
                |       MODIFIER_KEYS           { $$ = XkbLC_ModifierKeys; }
                |       KEYPAD_KEYS             { $$ = XkbLC_KeypadKeys; }
                |       FUNCTION_KEYS           { $$ = XkbLC_FunctionKeys; }
                |       ALTERNATE_GROUP         { $$ = XkbLC_AlternateGroup; }
                ;

DeclList        :       DeclList Decl
                        { $$ = AppendStmt($1, $2); }
                |       { $$ = NULL; }
                ;

Decl            :       OptMergeMode VarDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode VModDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode InterpretDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode KeyNameDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode KeyAliasDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode KeyTypeDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode SymbolsDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode ModMapDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode GroupCompatDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode IndicatorMapDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode IndicatorNameDecl
                        {
                            $2->merge = $1;
                            $$ = &$2->common;
                        }
                |       OptMergeMode ShapeDecl          { }
                |       OptMergeMode SectionDecl        { }
                |       OptMergeMode DoodadDecl         { }
                |       MergeMode STRING
                        {
                            $$ = &IncludeCreate(param->ctx, $2, $1)->common;
                            free($2);
                        }
                ;

VarDecl         :       Lhs EQUALS Expr SEMI
                        { $$ = VarCreate($1, $3); }
                |       Ident SEMI
                        { $$ = BoolVarCreate($1, 1); }
                |       EXCLAM Ident SEMI
                        { $$ = BoolVarCreate($2, 0); }
                ;

KeyNameDecl     :       KeyName EQUALS KeyCode SEMI
                        { $$ = KeycodeCreate($1, $3); }
                ;

KeyAliasDecl    :       ALIAS KeyName EQUALS KeyName SEMI
                        { $$ = KeyAliasCreate($2, $4); }
                ;

VModDecl        :       VIRTUAL_MODS VModDefList SEMI
                        { $$ = $2; }
                ;

VModDefList     :       VModDefList COMMA VModDef
                        { $$ = (VModDef *)AppendStmt(&$1->common, &$3->common); }
                |       VModDef
                        { $$ = $1; }
                ;

VModDef         :       Ident
                        { $$ = VModCreate($1, NULL); }
                |       Ident EQUALS Expr
                        { $$ = VModCreate($1, $3); }
                ;

InterpretDecl   :       INTERPRET InterpretMatch OBRACE
                            VarDeclList
                        CBRACE SEMI
                        { $2->def = $4; $$ = $2; }
                ;

InterpretMatch  :       KeySym PLUS Expr
                        { $$ = InterpCreate($1, $3); }
                |       KeySym
                        { $$ = InterpCreate($1, NULL); }
                ;

VarDeclList     :       VarDeclList VarDecl
                        { $$ = (VarDef *)AppendStmt(&$1->common, &$2->common); }
                |       VarDecl
                        { $$ = $1; }
                ;

KeyTypeDecl     :       TYPE String OBRACE
                            VarDeclList
                        CBRACE SEMI
                        { $$ = KeyTypeCreate($2, $4); }
                ;

SymbolsDecl     :       KEY KeyName OBRACE
                            SymbolsBody
                        CBRACE SEMI
                        { $$ = SymbolsCreate($2, (ExprDef *)$4); }
                ;

SymbolsBody     :       SymbolsBody COMMA SymbolsVarDecl
                        { $$ = (VarDef *)AppendStmt(&$1->common, &$3->common); }
                |       SymbolsVarDecl
                        { $$ = $1; }
                |       { $$ = NULL; }
                ;

SymbolsVarDecl  :       Lhs EQUALS Expr         { $$ = VarCreate($1, $3); }
                |       Lhs EQUALS ArrayInit    { $$ = VarCreate($1, $3); }
                |       Ident                   { $$ = BoolVarCreate($1, 1); }
                |       EXCLAM Ident            { $$ = BoolVarCreate($2, 0); }
                |       ArrayInit               { $$ = VarCreate(NULL, $1); }
                ;

ArrayInit       :       OBRACKET OptKeySymList CBRACKET
                        { $$ = $2; }
                |       OBRACKET ActionList CBRACKET
                        { $$ = ExprCreateUnary(EXPR_ACTION_LIST, EXPR_TYPE_ACTION, $2); }
                ;

GroupCompatDecl :       GROUP Integer EQUALS Expr SEMI
                        { $$ = GroupCompatCreate($2, $4); }
                ;

ModMapDecl      :       MODIFIER_MAP Ident OBRACE ExprList CBRACE SEMI
                        { $$ = ModMapCreate($2, $4); }
                ;

IndicatorMapDecl:       INDICATOR String OBRACE VarDeclList CBRACE SEMI
                        { $$ = IndicatorMapCreate($2, $4); }
                ;

IndicatorNameDecl:      INDICATOR Integer EQUALS Expr SEMI
                        { $$ = IndicatorNameCreate($2, $4, false); }
                |       VIRTUAL INDICATOR Integer EQUALS Expr SEMI
                        { $$ = IndicatorNameCreate($3, $5, true); }
                ;

ShapeDecl       :       SHAPE String OBRACE OutlineList CBRACE SEMI
                        { $$ = NULL; }
                |       SHAPE String OBRACE CoordList CBRACE SEMI
                        { $$ = NULL; }
                ;

SectionDecl     :       SECTION String OBRACE SectionBody CBRACE SEMI
                        { $$ = NULL; }
                ;

SectionBody     :       SectionBody SectionBodyItem     { $$ = NULL;}
                |       SectionBodyItem                 { $$ = NULL; }
                ;

SectionBodyItem :       ROW OBRACE RowBody CBRACE SEMI
                        { $$ = NULL; }
                |       VarDecl
                        { FreeStmt(&$1->common); $$ = NULL; }
                |       DoodadDecl
                        { $$ = NULL; }
                |       IndicatorMapDecl
                        { FreeStmt(&$1->common); $$ = NULL; }
                |       OverlayDecl
                        { $$ = NULL; }
                ;

RowBody         :       RowBody RowBodyItem     { $$ = NULL;}
                |       RowBodyItem             { $$ = NULL; }
                ;

RowBodyItem     :       KEYS OBRACE Keys CBRACE SEMI { $$ = NULL; }
                |       VarDecl
                        { FreeStmt(&$1->common); $$ = NULL; }
                ;

Keys            :       Keys COMMA Key          { $$ = NULL; }
                |       Key                     { $$ = NULL; }
                ;

Key             :       KeyName
                        { $$ = NULL; }
                |       OBRACE ExprList CBRACE
                        { FreeStmt(&$2->common); $$ = NULL; }
                ;

OverlayDecl     :       OVERLAY String OBRACE OverlayKeyList CBRACE SEMI
                        { $$ = NULL; }
                ;

OverlayKeyList  :       OverlayKeyList COMMA OverlayKey { $$ = NULL; }
                |       OverlayKey                      { $$ = NULL; }
                ;

OverlayKey      :       KeyName EQUALS KeyName          { $$ = NULL; }
                ;

OutlineList     :       OutlineList COMMA OutlineInList
                        { $$ = NULL;}
                |       OutlineInList
                        { $$ = NULL; }
                ;

OutlineInList   :       OBRACE CoordList CBRACE
                        { $$ = NULL; }
                |       Ident EQUALS OBRACE CoordList CBRACE
                        { $$ = NULL; }
                |       Ident EQUALS Expr
                        { FreeStmt(&$3->common); $$ = NULL; }
                ;

CoordList       :       CoordList COMMA Coord
                        { $$ = NULL; }
                |       Coord
                        { $$ = NULL; }
                ;

Coord           :       OBRACKET SignedNumber COMMA SignedNumber CBRACKET
                        { $$ = NULL; }
                ;

DoodadDecl      :       DoodadType String OBRACE VarDeclList CBRACE SEMI
                        { FreeStmt(&$4->common); $$ = NULL; }
                ;

DoodadType      :       TEXT    { $$ = 0; }
                |       OUTLINE { $$ = 0; }
                |       SOLID   { $$ = 0; }
                |       LOGO    { $$ = 0; }
                ;

FieldSpec       :       Ident   { $$ = $1; }
                |       Element { $$ = $1; }
                ;

Element         :       ACTION_TOK
                        { $$ = xkb_atom_intern(param->ctx, "action"); }
                |       INTERPRET
                        { $$ = xkb_atom_intern(param->ctx, "interpret"); }
                |       TYPE
                        { $$ = xkb_atom_intern(param->ctx, "type"); }
                |       KEY
                        { $$ = xkb_atom_intern(param->ctx, "key"); }
                |       GROUP
                        { $$ = xkb_atom_intern(param->ctx, "group"); }
                |       MODIFIER_MAP
                        {$$ = xkb_atom_intern(param->ctx, "modifier_map");}
                |       INDICATOR
                        { $$ = xkb_atom_intern(param->ctx, "indicator"); }
                |       SHAPE
                        { $$ = xkb_atom_intern(param->ctx, "shape"); }
                |       ROW
                        { $$ = XKB_ATOM_NONE; }
                |       SECTION
                        { $$ = XKB_ATOM_NONE; }
                |       TEXT
                        { $$ = XKB_ATOM_NONE; }
                ;

OptMergeMode    :       MergeMode       { $$ = $1; }
                |                       { $$ = MERGE_DEFAULT; }
                ;

MergeMode       :       INCLUDE         { $$ = MERGE_DEFAULT; }
                |       AUGMENT         { $$ = MERGE_AUGMENT; }
                |       OVERRIDE        { $$ = MERGE_OVERRIDE; }
                |       REPLACE         { $$ = MERGE_REPLACE; }
                |       ALTERNATE
                {
                    /*
                     * This used to be MERGE_ALT_FORM. This functionality was
                     * unused and has been removed.
                     */
                    $$ = MERGE_DEFAULT;
                }
                ;

OptExprList     :       ExprList        { $$ = $1; }
                |                       { $$ = NULL; }
                ;

ExprList        :       ExprList COMMA Expr
                        { $$ = (ExprDef *)AppendStmt(&$1->common, &$3->common); }
                |       Expr
                        { $$ = $1; }
                ;

Expr            :       Expr DIVIDE Expr
                        { $$ = ExprCreateBinary(EXPR_DIVIDE, $1, $3); }
                |       Expr PLUS Expr
                        { $$ = ExprCreateBinary(EXPR_ADD, $1, $3); }
                |       Expr MINUS Expr
                        { $$ = ExprCreateBinary(EXPR_SUBTRACT, $1, $3); }
                |       Expr TIMES Expr
                        { $$ = ExprCreateBinary(EXPR_MULTIPLY, $1, $3); }
                |       Lhs EQUALS Expr
                        { $$ = ExprCreateBinary(EXPR_ASSIGN, $1, $3); }
                |       Term
                        { $$ = $1; }
                ;

Term            :       MINUS Term
                        { $$ = ExprCreateUnary(EXPR_NEGATE, $2->value_type, $2); }
                |       PLUS Term
                        { $$ = ExprCreateUnary(EXPR_UNARY_PLUS, $2->value_type, $2); }
                |       EXCLAM Term
                        { $$ = ExprCreateUnary(EXPR_NOT, EXPR_TYPE_BOOLEAN, $2); }
                |       INVERT Term
                        { $$ = ExprCreateUnary(EXPR_INVERT, $2->value_type, $2); }
                |       Lhs
                        { $$ = $1;  }
                |       FieldSpec OPAREN OptExprList CPAREN %prec OPAREN
                        { $$ = ActionCreate($1, $3); }
                |       Terminal
                        { $$ = $1;  }
                |       OPAREN Expr CPAREN
                        { $$ = $2;  }
                ;

ActionList      :       ActionList COMMA Action
                        { $$ = (ExprDef *)AppendStmt(&$1->common, &$3->common); }
                |       Action
                        { $$ = $1; }
                ;

Action          :       FieldSpec OPAREN OptExprList CPAREN
                        { $$ = ActionCreate($1, $3); }
                ;

Lhs             :       FieldSpec
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_IDENT, EXPR_TYPE_UNKNOWN);
                            expr->value.str = $1;
                            $$ = expr;
                        }
                |       FieldSpec DOT FieldSpec
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_FIELD_REF, EXPR_TYPE_UNKNOWN);
                            expr->value.field.element = $1;
                            expr->value.field.field = $3;
                            $$ = expr;
                        }
                |       FieldSpec OBRACKET Expr CBRACKET
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_ARRAY_REF, EXPR_TYPE_UNKNOWN);
                            expr->value.array.element = XKB_ATOM_NONE;
                            expr->value.array.field = $1;
                            expr->value.array.entry = $3;
                            $$ = expr;
                        }
                |       FieldSpec DOT FieldSpec OBRACKET Expr CBRACKET
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_ARRAY_REF, EXPR_TYPE_UNKNOWN);
                            expr->value.array.element = $1;
                            expr->value.array.field = $3;
                            expr->value.array.entry = $5;
                            $$ = expr;
                        }
                ;

Terminal        :       String
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_VALUE, EXPR_TYPE_STRING);
                            expr->value.str = $1;
                            $$ = expr;
                        }
                |       Integer
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_VALUE, EXPR_TYPE_INT);
                            expr->value.ival = $1;
                            $$ = expr;
                        }
                |       Float
                        {
                            $$ = NULL;
                        }
                |       KeyName
                        {
                            ExprDef *expr;
                            expr = ExprCreate(EXPR_VALUE, EXPR_TYPE_KEYNAME);
                            strncpy(expr->value.keyName, $1, XkbKeyNameLength);
                            $$ = expr;
                        }
                ;

OptKeySymList   :       KeySymList      { $$ = $1; }
                |                       { $$ = NULL; }
                ;

KeySymList      :       KeySymList COMMA KeySym
                        { $$ = AppendKeysymList($1, $3); }
                |       KeySymList COMMA KeySyms
                        { $$ = AppendMultiKeysymList($1, $3); }
                |       KeySym
                        { $$ = CreateKeysymList($1); }
                |       KeySyms
                        { $$ = CreateMultiKeysymList($1); }
                ;

KeySyms         :       OBRACE KeySymList CBRACE
                        { $$ = $2; }
                ;

KeySym          :       IDENT   { $$ = $1; }
                |       SECTION { $$ = strdup("section"); }
                |       Integer
                        {
                            if ($1 < 10) {      /* XK_0 .. XK_9 */
                                $$ = malloc(2);
                                $$[0] = $1 + '0';
                                $$[1] = '\0';
                            }
                            else {
                                $$ = malloc(17);
                                snprintf($$, 17, "0x%x", $1);
                            }
                        }
                ;

SignedNumber    :       MINUS Number    { $$ = -$2; }
                |       Number          { $$ = $1; }
                ;

Number          :       FLOAT   { $$ = $1; }
                |       INTEGER { $$ = $1 * XkbGeomPtsPerMM; }
                ;

Float           :       FLOAT   { $$ = 0; }
                ;

Integer         :       INTEGER { $$ = $1; }
                ;

KeyCode         :       INTEGER { $$ = $1; }
                ;

KeyName         :       KEYNAME { strncpy($$, $1, XkbKeyNameLength); }
                ;

Ident           :       IDENT   { $$ = xkb_atom_steal(param->ctx, $1); }
                |       DEFAULT { $$ = xkb_atom_intern(param->ctx, "default"); }
                ;

String          :       STRING  { $$ = xkb_atom_steal(param->ctx, $1); }
                ;

OptMapName      :       MapName { $$ = $1; }
                |               { $$ = NULL; }
                ;

MapName         :       STRING  { $$ = $1; }
                ;

%%

#undef scanner
