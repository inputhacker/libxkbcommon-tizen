/************************************************************
 * Copyright (c) 1994 by Silicon Graphics Computer Systems, Inc.
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies and that both that copyright
 * notice and this permission notice appear in supporting
 * documentation, and that the name of Silicon Graphics not be
 * used in advertising or publicity pertaining to distribution
 * of the software without specific prior written permission.
 * Silicon Graphics makes no representation about the suitability
 * of this software for any purpose. It is provided "as is"
 * without any express or implied warranty.
 *
 * SILICON GRAPHICS DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
 * SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL SILICON
 * GRAPHICS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION  WITH
 * THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 ********************************************************/

#ifndef PARSEUTILS_H
#define PARSEUTILS_H

#include <stdio.h>

#include "xkbcomp-priv.h"

struct parser_param {
    struct xkb_context *ctx;
    void *scanner;
    XkbFile *rtrn;
};

#include "parser.h"

struct scanner_extra {
    struct xkb_context *ctx;
    char *scanFile;
    char scanBuf[1024];
    char *s;
};

extern ParseCommon *
AppendStmt(ParseCommon *to, ParseCommon *append);

extern ExprDef *
ExprCreate(enum expr_op_type op, enum expr_value_type type);

extern ExprDef *
ExprCreateUnary(enum expr_op_type op, enum expr_value_type type,
                ExprDef *child);

extern ExprDef *
ExprCreateBinary(enum expr_op_type op, ExprDef *left, ExprDef *right);

KeycodeDef *
KeycodeCreate(char keyName[XkbKeyNameLength], unsigned long value);

extern KeyAliasDef *
KeyAliasCreate(char keyName[XkbKeyNameLength], char real[XkbKeyNameLength]);

extern VModDef *
VModCreate(xkb_atom_t name, ExprDef *value);

extern VarDef *
VarCreate(ExprDef *name, ExprDef *value);

extern VarDef *
BoolVarCreate(xkb_atom_t nameToken, unsigned set);

extern InterpDef *
InterpCreate(char *sym, ExprDef *match);

extern KeyTypeDef *
KeyTypeCreate(xkb_atom_t name, VarDef *body);

extern SymbolsDef *
SymbolsCreate(char keyName[XkbKeyNameLength], ExprDef *symbols);

extern GroupCompatDef *
GroupCompatCreate(int group, ExprDef *def);

extern ModMapDef *
ModMapCreate(uint32_t modifier, ExprDef *keys);

extern IndicatorMapDef *
IndicatorMapCreate(xkb_atom_t name, VarDef *body);

extern IndicatorNameDef *
IndicatorNameCreate(int ndx, ExprDef *name, bool virtual);

extern ExprDef *
ActionCreate(xkb_atom_t name, ExprDef *args);

extern ExprDef *
CreateMultiKeysymList(ExprDef *list);

extern ExprDef *
CreateKeysymList(char *sym);

extern ExprDef *
AppendMultiKeysymList(ExprDef *list, ExprDef *append);

extern ExprDef *
AppendKeysymList(ExprDef *list, char *sym);

bool
LookupKeysym(const char *str, xkb_keysym_t *sym_rtrn);

extern IncludeStmt *
IncludeCreate(struct xkb_context *ctx, char *str, enum merge_mode merge);

extern void
CheckDefaultMap(struct xkb_context *ctx, XkbFile *maps, const char *fileName);

extern XkbFile *
CreateXKBFile(struct xkb_context *ctx, enum xkb_file_type type, char *name,
              ParseCommon *defs,
              unsigned flags);

extern bool
XKBParseFile(struct xkb_context *ctx, FILE *file, const char *file_name,
             XkbFile **out);

extern bool
XKBParseString(struct xkb_context *context, const char *string,
               const char *file_name,
               XkbFile **out);

extern void
FreeXKBFile(XkbFile *file);

extern void
FreeStmt(ParseCommon *stmt);

void
scanner_error(struct YYLTYPE *loc, void *scanner, const char *msg);

#endif /* PARSEUTILS_H */
