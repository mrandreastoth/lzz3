-----------------------------------------------------------------------------
-- class actions
-----------------------------------------------------------------------------
local BaseSpec            = require 'lzz/class/base_spec'
local DtorName            = require 'lzz/name/dtor_name'
local append              = require 'util/append'
local declareClass        = require 'lzz/scope/declare_class'
local defineClass         = require 'lzz/scope/define_class'
local defineFunctor       = require 'lzz/scope/define_functor'
local defineLazyClass     = require 'lzz/scope/define_lazy_class'
local nodes               = require 'lzz_nodes'
local setAccess           = require 'lzz/scope/set_access'
-----------------------------------------------------------------------------

--
-- on base specifiers
--

-- base-spec * -> obj-name
function nodes.BaseSpec1:onNode()
   return BaseSpec(false, false, self[1])
end
-- base-spec * -> VIRTUAL access-opt obj-name
function nodes.BaseSpec2:onNode()
   local access_opt = self[2]
   return BaseSpec(access_opt and access_opt.lexeme, true, self[3])
end
-- base-spec * -> access virtual-opt obj-name
function nodes.BaseSpec3:onNode()
   return BaseSpec(self[1].lexeme, self[2]~=nil, self[3])
end
-- lazy-base-spec -> base-spec base-init-opt
function nodes.LazyBaseSpec:onNode()
   local base_spec = self[1]
   base_spec.init = self[2]
   return base_spec
end
-- base-init -> LPAREN expr-list-opt RPAREN
function nodes.BaseInit:onNode()
   return {'paren', self[2]}
end

--
-- get base specifier list
--

local GetBaseSpecs = {}
-- base-spec-list -> base-spec
function GetBaseSpecs:onBaseSpecList1(node)
   return append({}, node[1])
end
-- base-spec-list -> base-spec-list COMMA base-spec
function GetBaseSpecs:onBaseSpecList2(node)
   return append(node[1]:accept(self), node[3])
end
-- base-clause -> COLON base-spec-list
function nodes.BaseClause:onNode()
   return self[2]:accept(GetBaseSpecs)
end

-- class-head -> class-key obj-name base-clause-opt
function nodes.ClassHead:onNode(app)
   local cls_def = {cls_key=self[1].lexeme, name=self[2], base_specs=self[3]}
   app:pushScope(defineClass(app:getCurrentScope(), cls_def))
end

--
-- on class definition
--

-- class-def -> class-head <* LBRACE mbr-decl-seq-opt RBRACE semi-opt
function nodes.ClassDef:onNode(app)
   app:popScope()
end

--
-- on access specifier
--

-- access-spec * -> access COLON
function nodes.AccessSpec:onNode(app)
   local access = self[1]
   setAccess(app:getCurrentScope(), access.loc, access.lexeme)
end

--
-- on class decl
--

local GetElabType = class()
-- xExx-decl-spec-seq -> elab-type
function GetElabType:onEDeclSpecSeq1(node)
   return self:result(node[1])
end
-- FExx-decl-spec-seq -> Fxxx-decl-spec-seq elab-type
function GetElabType:onEDeclSpecSeq2(node)
   node[1]:accept(self)
   return self:result(node[2])
end
-- Fxxx-decl-spec-seq -> FRIEND
function GetElabType:onFDeclSpecSeq1(node)
   self.is_frnd = true
end   
-- FExx-decl-spec-seq -> xExx-decl-spec-seq FRIEND
function GetElabType:onFDeclSpecSeq2(node)
   self.is_frnd = true
   return node[1]:accept(self)
end
-- return result
function GetElabType:result(elab_type)
   self.cls_key, self.name = table.unpack(elab_type)
   return setmetatable(self, nil)
end

-- class-decl -> xExx-decl-spec-seq SEMI
function nodes.ClassDecl:onNode(app)
   declareClass(app:getScope(), self[1]:accept(GetElabType()))
end

--
-- on ctor initializer
--

local GetMbrInitList = {}
-- mbr-init-list -> mbr-init
function GetMbrInitList:onMbrInitList1(node)
   return {node[1]}
end
-- mbr-init-list -> mbr-init-list COMMA mbr-init
function GetMbrInitList:onMbrInitList2(node)
   return append(node[1]:accept(self), node[3])
end

-- mbr-init * -> obj-name LPAREN block 2 RPAREN
function nodes.MbrInit1:onNode()
   -- tuple, name and expr list
   return {'paren', self[1], self[3].lexeme}
end
-- mbr-init * -> obj-name LBRACE block 2 RBRACE
function nodes.MbrInit2:onNode()
   -- tuple, name and expr list
   return {'brace', self[1], self[3].lexeme}
end

-- ctor-init -> COLON mbr-init-list
function nodes.CtorInit:onNode()
   local ctor_init = self[2]:accept(GetMbrInitList)
   ctor_init.loc = self[1].loc
   return ctor_init
end

--
-- on lazy class
--

-- lazy-class-head -> class-key obj-name param-decl-1-body RPAREN lazy-base-clause-opt
function nodes.LazyClassHead:onNode(app)
   local cls_def = {cls_key=self[1].lexeme, name=self[2], base_specs=self[5]}
   app:pushScope(defineLazyClass(app:getScope(), cls_def, self[3]))
end

-- lazy-class -> lazy-class-head LBRACE mbr-decl-seq-opt RBRACE semi-opt
function nodes.LazyClass:onNode(app)
   app:popScope()
end

--
-- on functor
--

-- functor-def -> functor-decl lazy-base-clause-opt try-opt LBRACE block-opt 7 RBRACE handler-seq-opt
function nodes.FunctorDef:onNode(app)
   local scope = app:getCurrentScope()
   local decl_spec, functor_def = table.unpack(self[1])
   functor_def.base_specs = self[2]
   functor_def.body = self[5]
   defineFunctor(scope, functor_def)
end

