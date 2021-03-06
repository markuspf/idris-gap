module IRTS.CodegenGAP (codegenGAP) where

import IRTS.CodegenCommon
import IRTS.Defunctionalise
import IRTS.Simplified
import Idris.Core.TT

import Data.Maybe
import Data.Char
import Data.List

codegenGAP :: CodeGenerator
codegenGAP ci = do
   writeFile (outputFile ci) ( "###################################################\n"
                            ++ "## GAP code generated by idris-gap code generator\n"
                            ++ "###################################################\n"
                            ++ "# Since functional programs rely on recursion, don't trap on recursion\n"
                            ++ "SetRecursionTrapInterval( 0 );"
                            ++ helpers 
                            ++ decls ++ "\n"
                            ++ out ++ "\n"
                            ++ start ++ "\n" 
                            )
   where decls = concatMap doTopLevel (simpleDecls ci) 
         out = concatMap doCodegen (simpleDecls ci) 
  
start = gapname (sMN 0 "runMain") ++ "();\n"

helpers = errCode ++ 
          doEcho ++
          mkStr ++
          doAppend ++
          boolInt ++ "\n"

errCode = "BindGlobal(\"error\", function(str) Error(str); end);\n"
doEcho = "BindGlobal(\"idris_writeStr\", function(str) Print(str); return 0; end);\n"
doAppend = "BindGlobal(\"idris_append\", function(l, r) return Concatenation(l, r); end);\n"
mkStr = "BindGlobal(\"mkStr\", function(l) return [l]; end);\n"
boolInt = "BindGlobal(\"idris_boolToInt\", function(b) if b then return 1; else return 0; fi; end);\n"

gapname :: Name -> String
gapname n = "idris_" ++ concatMap gapchar (showCG n)
  where gapchar x | isAlpha x || isDigit x = [x]
                  | otherwise = "_" ++ show (fromEnum x) ++ "_"

var :: Name -> String
var n = gapname n

loc :: Int -> String
loc i = "loc" ++ show i

getTags :: [(Name, DDecl)] -> [(Name, Int)]
getTags = mapMaybe getTag
  where
    getTag (n, DConstructor _ t _) = Just (n, t)
    getTag _ = Nothing

doTopLevel :: (Name, SDecl) -> String
doTopLevel (n, _) = cgTopLevel n 

cgTopLevel :: Name -> String
cgTopLevel n = "DeclareGlobalFunction(\"" ++ gapname n ++ "\");\n"

doCodegen :: (Name, SDecl) -> String
doCodegen (n, SFun _ args i def) = cgFun n args i def

cgFun :: Name -> [Name] -> Int -> SExp -> String
cgFun n args i def 
    = "InstallGlobalFunction(" ++ gapname n ++ ",function("
                ++ showSep "," (map (loc . fst) (zip [0..] args)) ++ ")\n"
                ++ "local " ++ (showSep "," (map loc [l..l + i])) ++ ";\n"
                ++ cgBody doRet def ++ "end);\n\n"
    where l = length args

cgBody :: (String -> String) -> SExp -> String
cgBody ret (SV (Glob n)) = ret $ gapname n ++ "()"
cgBody ret (SV (Loc i)) = ret $ loc i 
cgBody ret (SApp _ f args) = ret $ gapname f ++ "(" ++ 
                                   showSep "," (map cgVar args) ++ ")"

cgBody ret (SLet (Loc i) v sc)
   = cgBody (\x -> loc i ++ " := " ++ x ++ ";\n") v ++
     cgBody ret sc
cgBody ret (SUpdate n e)
   = cgBody ret e
cgBody ret (SProj e i)
   = ret $ cgVar e ++ "[" ++ show (i + 2) ++ "]"
cgBody ret (SCon _ t n args)
   = ret $ "[" ++ showSep "," 
              (show t : (map cgVar args)) ++ "]"
cgBody ret (SCase _ e alts)
   = let scrvar = cgVar e 
         scr = if any conCase alts then scrvar ++ "[1]" else scrvar in
         cgAlts ret scr scrvar alts
  where conCase (SConCase _ _ _ _ _) = True
        conCase _ = False
cgBody ret (SChkCase e alts)
   = let scrvar = cgVar e 
         scr = if any conCase alts then scrvar ++ "[1]" else scrvar in
         cgAlts ret scr scrvar alts 
  where conCase (SConCase _ _ _ _ _) = True
        conCase _ = False
cgBody ret (SConst c) = ret $ cgConst c
cgBody ret (SOp op args) = ret $ cgOp op (map cgVar args)
cgBody ret SNothing = ret "0"
cgBody ret (SError x) = ret $ "Error( " ++ x ++ ")"
cgBody ret _ = ret $ "Error(\"NOT IMPLEMENTED!!!!\")"

doRet :: String -> String
doRet str = "return (" ++ str ++ ");\n"

cgAlts :: (String -> String) -> String -> String -> [SAlt] -> String
cgAlts ret scr scrvar (a : as)
   = "if " ++ cgAltComp scr a ++ " then\n    "
           ++ (cgAltBody ret scrvar a)
           ++ (cgAlts' ret scr scrvar (filter (not . defCase) as))  
           ++ (cgDef ret (find defCase as)) 
           ++ "fi;\n"
   where defCase (SDefaultCase _) = True
         defCase _ = False


cgAlts' :: (String -> String) -> String -> String -> [SAlt] -> String
cgAlts' ret scr scrvar as 
   = showSep "\n" (map cgAltProc as)
   where cgAltProc a = "elif " ++ (cgAltComp scr a) ++ " then\n    " ++ (cgAltBody ret scrvar a)

cgDef :: (String -> String) -> (Maybe SAlt) -> String
cgDef ret (Just (SDefaultCase exp)) = "else\n" ++ cgBody ret exp
cgDef _ _ = ""

cgAltComp :: String -> SAlt -> String
cgAltComp scrvar (SConstCase t _)     = "(" ++ scrvar ++ " = " ++ show t ++ ")"
cgAltComp scrvar (SConCase _ t _ _ _) = "(" ++ scrvar ++ " = " ++ show t ++ ")"
cgAltComp scrvar (SDefaultCase _) = "true"

cgAltBody :: (String -> String) -> String -> SAlt -> String
cgAltBody ret scr (SConstCase _ exp)
   = cgBody ret exp
cgAltBody ret scr (SConCase lv t n args exp)
   = project 1 lv args ++ "\n" ++ cgBody ret exp
   where project i v [] = ""
         project i v (n : ns) = loc v ++ " := " ++ scr ++ "[" ++ show (i + 1) ++ "];\n"
                                      ++ project (i + 1) (v + 1) ns
cgAltBody ret scr (SDefaultCase exp)
   = cgBody ret exp

cgVar :: LVar -> String
cgVar (Loc i) = loc i 
cgVar (Glob n) = var n

cgConst :: Const -> String
cgConst (I i) = show i
cgConst (BI i) = show i
cgConst (Str s) = show s
cgConst TheWorld = "0"
cgConst x | isTypeConst x = "0"
cgConst x = error $ "Constant " ++ show x ++ " not compilable yet"

cgOp :: PrimFn -> [String] -> String
cgOp (LPlus (ATInt _)) [l, r] 
     = "(" ++ l ++ " + " ++ r ++ ")"
cgOp (LMinus (ATInt _)) [l, r] 
     = "(" ++ l ++ " - " ++ r ++ ")"
cgOp (LTimes (ATInt _)) [l, r] 
     = "(" ++ l ++ " * " ++ r ++ ")"
cgOp (LEq (ATInt _)) [l, r] 
     = "idris_boolToInt(" ++ l ++ " = " ++ r ++ ")"
cgOp (LSLt (ATInt _)) [l, r] 
     = "idris_boolToInt(" ++ l ++ " < " ++ r ++ ")"
cgOp (LSLe (ATInt _)) [l, r] 
     = "idris_boolToInt(" ++ l ++ " <= " ++ r ++ ")"
cgOp (LSGt (ATInt _)) [l, r] 
     = "idris_boolToInt(" ++ l ++ " > " ++ r ++ ")"
cgOp (LSGe (ATInt _)) [l, r] 
     = "idris_boolToInt(" ++ l ++ " >= " ++ r ++ ")"
cgOp (LIntStr _) [x] = "String(" ++ x ++ ")"
cgOp (LSExt _ _) [x] = x
cgOp (LTrunc _ _) [x] = x
cgOp LWriteStr [_,str] = "idris_writeStr(" ++ str ++ ")"
cgOp LStrConcat [l,r] = "idris_append(" ++ l ++ ", " ++ r ++ ")"
cgOp op exps = "Error(\"OPERATOR " ++ show op ++ " NOT IMPLEMENTED!!!!\");\n"



