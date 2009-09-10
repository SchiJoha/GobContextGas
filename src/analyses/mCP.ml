(* 
 * Copyright (c) 2005-2007,
 *     * University of Tartu
 *     * Vesal Vojdani <vesal.vojdani@gmail.com>
 *     * Kalmer Apinis <kalmera@ut.ee>
 *     * Jaak Randmets <jaak.ra@gmail.com>
 *     * Toomas Römer <toomasr@gmail.com>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 * 
 *     * Redistributions in binary form must reproduce the above copyright notice,
 *       this list of conditions and the following disclaimer in the documentation
 *       and/or other materials provided with the distribution.
 * 
 *     * Neither the name of the University of Tartu nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)
 
include Cil
include Pretty

module GU = Goblintutil
module JB = Json_type.Browse

module Domain (Base : Analyses.Spec)=
struct
  exception DomainBroken
  
  (* This type should contain all analyses that do not depend on base.*)
  type e = Base      of Base.Dom.t
         | VarEq of VarEq.Spec.Dom.t
         | Bad
  
  (* We pair list of configurable analyses with multithreadidness flag domain. *)
  type t = e list
  
  (* Constructor scheme stuff: we take a list of values and then filter out
     ones that are disabled. *)
  let int_ds = JB.make_table (JB.objekt (JB.field GU.conf "analyses")) 
  let constr_scheme xs =
    let f (s,g) y : e list = 
      if JB.bool (JB.field int_ds s) 
      then (g ()) :: y
      else y
    in
    List.fold_right f xs []
    
  (* constructors *)
  let top () = constr_scheme
    [("base"  ,fun () -> Base  (Base.Dom.top ()))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.Dom.top ()))]
      
  let bot () = constr_scheme
    [("base"  ,fun () -> Base  (Base.Dom.bot ()))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.Dom.bot ()))]
  

  let startstate () = constr_scheme
    [("base"  ,fun () -> Base  (Base.startstate))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.startstate))]

  let otherstate () = constr_scheme
    [("base"  ,fun () -> Base  (Base.otherstate))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.otherstate))]

  (* element lattice functions *)
  let narrow' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Dom.narrow x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Dom.narrow x y)
      | _ -> raise DomainBroken

  let widen' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Dom.widen x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Dom.widen x y)
      | _ -> raise DomainBroken

  let is_top' x =
    match x with
      | Base x -> Base.Dom.is_top x
      | VarEq x -> VarEq.Spec.Dom.is_top x
      | _ -> raise DomainBroken
  
  let is_bot' x =
    match x with
      | Base x -> Base.Dom.is_bot x
      | VarEq x -> VarEq.Spec.Dom.is_bot x
      | _ -> raise DomainBroken

  let meet' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Dom.meet x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Dom.meet x y)
      | _ -> raise DomainBroken

  let join' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Dom.join x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Dom.join x y)
      | _ -> raise DomainBroken

  let leq' x y =
    match x, y with
      | Base x, Base y -> Base.Dom.leq x y
      | VarEq x, VarEq y -> VarEq.Spec.Dom.leq x y
      | _ -> raise DomainBroken
      
  let short' w x =
    match x with
      | Base x -> Base.Dom.short w x
      | VarEq x -> VarEq.Spec.Dom.short w x
      | _ -> raise DomainBroken
      
  let toXML_f' sf x =
    match x with
      | Base x -> Base.Dom.toXML_f (fun w x -> sf w (Base x)) x
      | VarEq x -> VarEq.Spec.Dom.toXML_f (fun w x -> sf w (VarEq x)) x
      | _ -> raise DomainBroken
      
  let pretty_f' sf () x =
    match x with
      | Base x -> Base.Dom.pretty_f (fun w x -> sf w (Base x)) () x
      | VarEq x -> VarEq.Spec.Dom.pretty_f (fun w x -> sf w (VarEq x)) () x
      | _ -> raise DomainBroken
      
  let toXML' x = toXML_f' short' x
      
  let pretty' x = pretty_f' short' x
      
  let isSimple' x =
    match x with
      | Base x -> Base.Dom.isSimple x
      | VarEq x -> VarEq.Spec.Dom.isSimple x
      | _ -> raise DomainBroken

  let compare' x y =
    match x, y with
      | Base x, Base y -> Base.Dom.compare x y
      | VarEq x, VarEq y -> VarEq.Spec.Dom.compare x y
      | _ -> raise DomainBroken

  let equal' x y =
    match x, y with
      | Base x, Base y -> Base.Dom.equal x y
      | VarEq x, VarEq y -> VarEq.Spec.Dom.equal x y
      | _ -> raise DomainBroken

  let hash' x =
    match x with
      | Base x-> Base.Dom.hash x
      | VarEq x-> VarEq.Spec.Dom.hash x
      | _ -> raise DomainBroken

  (* combining element functions to list functions *)
  
  let name () = "Domain"
  let narrow = List.map2 narrow' 
  let widen  = List.map2 widen'  
  let meet   = List.map2 meet'   
  let join   = List.map2 join'   

  let is_top = List.for_all is_top' 
  let is_bot = List.for_all is_bot'
  let leq    = List.for_all2 leq' 
    
  let short _ = List.fold_left (fun p n -> p ^ short' 30 n ^ "; " ) ""
  
  let pretty_f _ () x = 
    match x with
      | [] -> text "()"
      | x :: [] -> pretty' () x
      | x :: y ->
        let first = pretty' () x in
        let rest  = List.fold_left (fun p n->p ++ text "," ++ pretty' () n) (text "") y in
        text "(" ++ first ++ rest ++ text ")"

  let pretty = pretty_f short 

  let toXML_f sf x =
    let esc = Goblintutil.escape in
    let nodes = List.map toXML' x in
    let node_leaf = if nodes = [] then "Leaf" else "Node" in
      Xml.Element (node_leaf, [("text", esc (sf Goblintutil.summary_length x))], nodes)

  let toXML = toXML_f short
  
  let compare =
    let f a x y =
      if a == 0 
      then compare' x y
      else 0
    in
    List.fold_left2 f 0
    
  let isSimple = List.for_all isSimple'
  let equal    = List.for_all2 equal' 
  let hash     = List.fold_left (fun x y -> x lxor (hash' y)) 0 

end

module GlobalDomain (Base : Analyses.Spec)=
struct
  exception DomainBroken
  
  (* This type should contain all analyses. *)
  type e = VarEq of VarEq.Spec.Glob.Val.t
         | Base      of Base.Glob.Val.t
         | Bad
  
  (* We pair list of configurable analyses with multithreadidness flag domain. *)
  type t = e list
  
  (* Constructor scheme stuff: we take a list of values and then filter out
     ones that are disabled. *)
  let int_ds = JB.make_table (JB.objekt (JB.field GU.conf "analyses")) 
  let constr_scheme xs =
    let f (s,g) y : e list = 
      if JB.bool (JB.field int_ds s) 
      then (g ()) :: y
      else y
    in
    List.fold_right f xs []
    
  (* constructors *)
  let top () = constr_scheme
    [("base"  ,fun () -> Base  (Base.Glob.Val.top ()))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.Glob.Val.top ()))]
      
  let bot () = constr_scheme
    [("base"  ,fun () -> Base  (Base.Glob.Val.bot ()))
    ;("var_eq",fun () -> VarEq (VarEq.Spec.Glob.Val.bot ()))]

  (* element lattice functions *)
  
  let narrow' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Glob.Val.narrow x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Glob.Val.narrow x y)
      | _ -> raise DomainBroken

  let widen' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Glob.Val.widen x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Glob.Val.widen x y)
      | _ -> raise DomainBroken

  let is_top' x =
    match x with
      | Base x -> Base.Glob.Val.is_top x
      | VarEq x -> VarEq.Spec.Glob.Val.is_top x
      | _ -> raise DomainBroken
  
  let is_bot' x =
    match x with
      | Base x -> Base.Glob.Val.is_bot x
      | VarEq x -> VarEq.Spec.Glob.Val.is_bot x
      | _ -> raise DomainBroken

  let meet' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Glob.Val.meet x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Glob.Val.meet x y)
      | _ -> raise DomainBroken

  let join' x y =
    match x, y with
      | Base x, Base y -> Base (Base.Glob.Val.join x y)
      | VarEq x, VarEq y -> VarEq (VarEq.Spec.Glob.Val.join x y)
      | _ -> raise DomainBroken

  let leq' x y =
    match x, y with
      | Base x, Base y -> Base.Glob.Val.leq x y
      | VarEq x, VarEq y -> VarEq.Spec.Glob.Val.leq x y
      | _ -> raise DomainBroken
      
  let short' w x =
    match x with
      | Base x -> Base.Glob.Val.short w x
      | VarEq x -> VarEq.Spec.Glob.Val.short w x
      | _ -> raise DomainBroken
      
  let toXML_f' sf x =
    match x with
      | Base x -> Base.Glob.Val.toXML_f (fun w x -> sf w (Base x)) x
      | VarEq x -> VarEq.Spec.Glob.Val.toXML_f (fun w x -> sf w (VarEq x)) x
      | _ -> raise DomainBroken
      
  let pretty_f' sf () x =
    match x with
      | Base x -> Base.Glob.Val.pretty_f (fun w x -> sf w (Base x)) () x
      | VarEq x -> VarEq.Spec.Glob.Val.pretty_f (fun w x -> sf w (VarEq x)) () x
      | _ -> raise DomainBroken
      
  let toXML' x = toXML_f' short' x
      
  let pretty' x = pretty_f' short' x
      
  let isSimple' x =
    match x with
      | Base x -> Base.Glob.Val.isSimple x
      | VarEq x -> VarEq.Spec.Glob.Val.isSimple x
      | _ -> raise DomainBroken

  let compare' x y =
    match x, y with
      | Base x, Base y -> Base.Glob.Val.compare x y
      | VarEq x, VarEq y -> VarEq.Spec.Glob.Val.compare x y
      | _ -> raise DomainBroken

  let equal' x y =
    match x, y with
      | Base x, Base y -> Base.Glob.Val.equal x y
      | VarEq x, VarEq y -> VarEq.Spec.Glob.Val.equal x y
      | _ -> raise DomainBroken

  let hash' x =
    match x with
      | Base x-> Base.Glob.Val.hash x
      | VarEq x-> VarEq.Spec.Glob.Val.hash x
      | _ -> raise DomainBroken

  (* combining element functions to list functions *)
  
  let name () = "Domain"
  let narrow = List.map2 narrow' 
  let widen  = List.map2 widen'  
  let meet   = List.map2 meet'   
  let join   = List.map2 join'   

  let is_top = List.for_all is_top' 
  let is_bot = List.for_all is_bot'
  let leq    = List.for_all2 leq' 
    
  let short _ = List.fold_left (fun p n -> p ^ short' 30 n ^ "; " ) ""
  
  let pretty_f _ () x = 
    match x with
      | [] -> text "()"
      | x :: [] -> pretty' () x
      | x :: y ->
        let first = pretty' () x in
        let rest  = List.fold_left (fun p n->p ++ text "," ++ pretty' () n) (text "") y in
        text "(" ++ first ++ rest ++ text ")"

  let pretty = pretty_f short 

  let toXML_f sf x =
    let esc = Goblintutil.escape in
    let nodes = List.map toXML' x in
    let node_leaf = if nodes = [] then "Leaf" else "Node" in
      Xml.Element (node_leaf, [("text", esc (sf Goblintutil.summary_length x))], nodes)

  let toXML = toXML_f short
  
  let compare =
    let f a x y =
      if a == 0 
      then compare' x y
      else 0
    in
    List.fold_left2 f 0
    
  let isSimple = List.for_all isSimple'
  let equal    = List.for_all2 equal' 
  let hash     = List.fold_left (fun x y -> x lxor (hash' y)) 0 

end

module MakeSpec (Base: Analyses.Spec) = 
struct
  module Dom  = Domain (Base)
  module Glob = 
  struct
    module Var = Basetype.Variables
    module Val = GlobalDomain (Base)
  end
  
  (* elementwise operations *)
  
  let globalBase g (x:Glob.Var.t) : Base.Glob.Val.t =
    let f c n = 
      match n with
        | Glob.Val.Base x -> Some x
        | _ -> c 
    in
    match List.fold_left f None (g x) with
      | Some x -> x
      | None -> raise Glob.Val.DomainBroken

  let globalVarEq g (x:Glob.Var.t) : VarEq.Spec.Glob.Val.t =
    let f c n = 
      match n with
        | Glob.Val.VarEq x -> Some x
        | _ -> c 
    in
    match List.fold_left f None (g x) with
      | Some x -> x
      | None -> raise Glob.Val.DomainBroken

  let assign' a lv exp g x =
    match x with
      | Dom.Base x -> Dom.Base (Base.assign a lv exp (globalBase g) x)
      | Dom.VarEq x -> Dom.VarEq (VarEq.Spec.assign a lv exp (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken

  let body' a fn g st =
    match st with
      | Dom.Base x -> Dom.Base (Base.body a fn (globalBase g) x)
      | Dom.VarEq x -> Dom.VarEq (VarEq.Spec.body a fn (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken
  
  let return' a r fn g st =
    match st with
      | Dom.Base x -> Dom.Base (Base.return a r fn (globalBase g) x)
      | Dom.VarEq x -> Dom.VarEq (VarEq.Spec.return a r fn (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken

  let branch' a exp tv g st =
    match st with
      | Dom.Base x -> Dom.Base (Base.branch a exp tv (globalBase g) x)
      | Dom.VarEq x -> Dom.VarEq (VarEq.Spec.branch a exp tv (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken
  
  let special_fn' a r v args g st =
    match st with
      | Dom.Base x -> List.map (fun x -> Dom.Base x) (Base.special_fn a r v args (globalBase g) x)
      | Dom.VarEq x -> List.map (fun x -> Dom.VarEq x) (VarEq.Spec.special_fn a r v args (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken

  let enter_func' a r v args g st =
    match st with
      | Dom.Base x -> List.map (fun (x,y) -> Dom.Base x, Dom.Base y) (Base.enter_func a r v args (globalBase g) x)
      | Dom.VarEq x -> List.map (fun (x,y) -> Dom.VarEq x,Dom.VarEq y) (VarEq.Spec.enter_func a r v args (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken

  let leave_func' a r v args g st1 st2 =
    match st1, st2 with
      | Dom.Base x, Dom.Base y -> Dom.Base (Base.leave_func a r v args (globalBase g) x y)
      | Dom.VarEq x, Dom.VarEq y -> Dom.VarEq (VarEq.Spec.leave_func a r v args (globalVarEq g) x y)
      | _ -> raise Dom.DomainBroken
  
  let eval_funvar' a exp g st : Cil.varinfo list =
    match st with
      | Dom.Base x -> Base.eval_funvar a exp (globalBase g) x
      | Dom.VarEq x -> VarEq.Spec.eval_funvar a exp (globalVarEq g) x
      | _ -> raise Dom.DomainBroken
  
  let fork' a r v args g st =
    match st with
      | Dom.Base x -> List.map (fun (x,y) -> x, Dom.Base y) (Base.fork a r v args (globalBase g) x)
      | Dom.VarEq x -> List.map (fun (x,y) -> x, Dom.VarEq y) (VarEq.Spec.fork a r v args (globalVarEq g) x)
      | _ -> raise Dom.DomainBroken
  
  let reset_diff' st =
    match st with
      | Dom.Base x -> Dom.Base (Base.reset_diff x)
      | Dom.VarEq x -> Dom.VarEq (VarEq.Spec.reset_diff x)
      | _ -> raise Dom.DomainBroken

  let rec replaceg x ws = 
    match ws, x with
      | [], _ -> []
      | Glob.Val.Base x :: ws, Glob.Val.Base y -> Glob.Val.Base y :: ws
      | Glob.Val.VarEq x :: ws, Glob.Val.VarEq y -> Glob.Val.VarEq y :: ws
      | w::ws, x -> w :: replaceg x ws
      
  let rec replace x ws = 
    match ws, x with
      | [], _ -> []
      | Dom.Base x :: ws, Dom.Base y -> Dom.Base y :: ws
      | Dom.VarEq x :: ws, Dom.VarEq y -> Dom.VarEq y :: ws
      | w::ws, x -> w :: replace x ws

  let get_diff' st =
    match st with
      | Dom.Base x -> List.map (fun (x,y) -> x, replaceg (Glob.Val.Base y) (Glob.Val.bot ())) (Base.get_diff x)
      | Dom.VarEq x -> List.map (fun (x,y) -> x, replaceg (Glob.Val.VarEq y) (Glob.Val.bot ())) (VarEq.Spec.get_diff x)
      | _ -> raise Dom.DomainBroken
  
  let query' a g st =
    match st with
      | Dom.Base x -> Base.query a (globalBase g) x
      | Dom.VarEq x -> VarEq.Spec.query a (globalVarEq g) x
      | _ -> raise Dom.DomainBroken
  
  (* analysis spec stuff *)
  let name = "analyses"
  let finalize () = ()
  let init     () = ()

  let otherstate = Dom.otherstate ()
  let startstate = Dom.startstate ()
  let should_join _ _ = true
  
  let es_to_string f _ = f.svar.vname
  let get_diff st = List.flatten (List.map get_diff' st)
  let reset_diff = List.map reset_diff'  

  (* queries *)
  let rec query_imp g s q =
    let ls = List.map (fun x -> query' (query_imp g s) g x q) s in
    List.fold_left Queries.Result.meet (Queries.Result.top ()) ls
  
  let query _ = query_imp

  (* transfer functions *)
  let return a r fn g s   = List.map (return' (query_imp g s) r fn g) s
  let body a fn g s       = List.map (body' (query_imp g s) fn g) s
  let branch a exp tv g s = List.map (branch' (query_imp g s) exp tv g) s
  let assign a lv exp g s = List.map (assign' (query_imp g s) lv exp g) s
  let leave_func a r v args g s = List.map2 (leave_func' (query_imp g s) r v args g) s

  (* return all unique variables that analyses report *)
  let eval_funvar a exp g st : Cil.varinfo list = 
    let unique x = List.fold_right (fun x xs -> if List.mem x xs then xs else x::xs) x [] in
    unique (List.flatten (List.map (eval_funvar' (query_imp g st) exp g) st))

  (* fork over all analyses and combine values of equal varinfos *)
  let fork a r v args g st =
    let start_val = st in (* do not know if it should be st or top *)
    let f rs xs = 
      let g rs (v,s) : (Cil.varinfo * Dom.t) list=
        if List.mem_assoc v rs then 
          (v, replace s (List.assoc v rs)) :: List.remove_assoc v rs 
        else 
          (v, replace s start_val) :: rs
      in
      List.fold_left g rs xs
    in
    List.fold_left f [] (List.map (fork' (query_imp g st) r v args g) st) 

  (* We start with maping all enter_func to analyses, then we match together all
     possible combinations. *)
  let enter_func a r v args g st = 
    let f ps rs =
      let h (s,t) = List.map (fun (ss,tt) -> ss@[s], tt@[t]) ps in
      List.flatten (List.map h rs)
    in
    match List.map (enter_func' (query_imp g st) r v args g) st with
       | []      -> []
       | x :: xs -> List.fold_left f (List.map (fun (x,y) -> [x],[y]) x) xs
  
  let special_fn a r v args g st =
    let f ps rs =
      let h s = List.map (fun ss -> ss@[s]) ps in
      List.flatten (List.map h rs)
    in
    match List.map (special_fn' (query_imp g st) r v args g) st with
       | []      -> []
       | x :: xs -> List.fold_left f (List.map (fun x -> [x]) x) xs
    
end

module Analysis = Multithread.Forward(MakeSpec (Base.Spec)) 
