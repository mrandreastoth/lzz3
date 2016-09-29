-----------------------------------------------------------------------------
-- namespace
-----------------------------------------------------------------------------
local nodes               = require 'lzz_nodes'
local openNs              = require 'lzz/namespace/open_ns'
-----------------------------------------------------------------------------

-- open-namespace -> NAMESPACE obj-name LBRACE
function nodes.OpenNamespace1:onNode(app)
   app:pushScope(openNs(app:getCurrentScope(), self[1].loc, self[2]))
end

-- open-namespace -> NAMESPACE LBRACE
function nodes.OpenNamespace2:onNode(app)
   app:pushScope(openNs(app:getCurrentScope(), self[1].loc))
end

-- namespace * -> open-namespace decl-seq-opt RBRACE
function nodes.Namespace:onNode(app)
   app:popScope()
end
