(** An analysis for the detection of use-after-free vulnerabilities. *)

open GoblintCil
open Analyses
open MessageCategory

(* TODO: Maybe come up with a better name for top at some point? *)
module ToppedVarInfoSet = SetDomain.ToppedSet(CilType.Varinfo)(struct let topname = "Unknown" end)

module Spec : Analyses.MCPSpec =
struct
  include Analyses.DefaultSpec

  let name () = "useafterfree"

  module D = ToppedVarInfoSet
  module C = Lattice.Unit

  (** TODO: Try out later in benchmarks to see how we perform with and without context-sensititivty *)
  let context _ _ = ()


  (* HELPER FUNCTIONS *)

  (* Took inspiration from malloc_null *)
  let may (f:'a -> 'b) (x:'a option) : unit =
    match x with
    | Some x -> f x
    | None -> ()

  (* Also took inspiration from malloc_null *)
  let get_concrete_lval (ask:Queries.ask) (lval:lval) =
    match ask.f (Queries.MayPointTo (mkAddrOf lval)) with
    | a when Queries.LS.cardinal a = 1 && not (Queries.LS.mem (dummyFunDec.svar, `NoOffset) a) ->
      let v, o = Queries.LS.choose a in
      Some v
    | _ -> None

  (* And also took inspiration from malloc_null *)
  let get_concrete_exp (exp:exp) =
    match constFold true exp with
    | CastE (_, Lval (Var v, _))
    | Lval (Var v, _) -> Some v
    | _ -> None

  let rec warn_lval_might_contain_freed ?(is_double_free = false) (transfer_fn_name:string) (lval:lval) ctx =
    let state = ctx.local in
    let cwe_number = if is_double_free then 415 else 416 in
    let rec offset_might_contain_freed offset =
      match offset with
      | NoOffset -> ()
      | Field (f, o) -> offset_might_contain_freed o
      | Index (e, o) -> warn_exp_might_contain_freed transfer_fn_name e ctx; offset_might_contain_freed o
    in
    match lval with
    (* Case: lval is a variable *)
    | (Var v, o) ->
      offset_might_contain_freed o;
      if D.mem v state then
        M.warn ~category:(Behavior (Undefined UseAfterFree)) ~tags:[CWE cwe_number] "lval in \"%s\" is a maybe freed pointer" transfer_fn_name
      else ()
    (* Case: lval is an object whose address is in a pointer *)
    | (Mem e, o) ->
      offset_might_contain_freed o;
      begin match get_concrete_exp e with
        | Some v ->
          if D.mem v state then
            M.warn ~category:(Behavior (Undefined UseAfterFree)) ~tags:[CWE cwe_number] "lval in \"%s\" points to a maybe freed pointer" transfer_fn_name
          else ()
        | None -> ()
      end
  (* TODO: Wasn't sure about the snippet below. Clean it up at some point *)
  (* begin match ctx.ask (Queries.MayPointTo e) with
      (* TODO: Do we need the second conjunct? *)
      | a when not (Queries.LS.is_top a) && not (Queries.LS.mem (dummyFunDec.svar, `NoOffset) a) ->
      (* TODO: Took inspiration from malloc_null. Double check if it makes sense. *)
      let v, o = Queries.LS.choose a in
      if D.mem v state then
        M.warn ~category:(Behavior (Undefined UseAfterFree)) "lval in \"%s\" points to a maybe freed pointer" transfer_fn_name
      else ()
      | _ -> ()
      end *)

  and warn_exp_might_contain_freed ?(is_double_free = false) (transfer_fn_name:string) (exp:exp) ctx =
    match exp with
    (* Base recursion cases *)
    | Const _
    | SizeOf _
    | SizeOfStr _
    | AlignOf _
    | AddrOfLabel _ -> ()
    (* Non-base cases *)
    | Real e
    | Imag e
    | SizeOfE e
    | AlignOfE e
    | UnOp (_, e, _)
    | CastE (_, e) -> warn_exp_might_contain_freed ~is_double_free transfer_fn_name e ctx
    | BinOp (_, e1, e2, _) ->
      warn_exp_might_contain_freed ~is_double_free transfer_fn_name e1 ctx;
      warn_exp_might_contain_freed ~is_double_free transfer_fn_name e2 ctx
    | Question (e1, e2, e3, _) ->
      warn_exp_might_contain_freed ~is_double_free transfer_fn_name e1 ctx;
      warn_exp_might_contain_freed ~is_double_free transfer_fn_name e2 ctx;
      warn_exp_might_contain_freed ~is_double_free transfer_fn_name e3 ctx
    (* Lval cases (need [warn_lval_might_contain_freed] for them) *)
    | Lval lval
    | StartOf lval
    | AddrOf lval -> warn_lval_might_contain_freed ~is_double_free transfer_fn_name lval ctx


  (* TRANSFER FUNCTIONS *)

  let assign ctx (lval:lval) (rval:exp) : D.t =
    let state = ctx.local in
    warn_lval_might_contain_freed "assign" lval ctx;
    warn_exp_might_contain_freed "assign" rval ctx;
    match get_concrete_exp rval, get_concrete_lval (Analyses.ask_of_ctx ctx) lval with
    | Some v_exp, Some v_lval ->
      if D.mem v_exp state then
        D.add v_lval state
      else state
    | _ -> state

  let branch ctx (exp:exp) (tv:bool) : D.t =
    let state = ctx.local in
    warn_exp_might_contain_freed "branch" exp ctx;
    state

  let body ctx (f:fundec) : D.t =
    ctx.local

  let return ctx (exp:exp option) (f:fundec) : D.t =
    let state = ctx.local in
    may (fun x -> warn_exp_might_contain_freed "return" x ctx) exp;
    state

  (* TODO: FINISH *)
  let enter ctx (lval:lval option) (f:fundec) (args:exp list) : (D.t * D.t) list =
    let caller_state = ctx.local in
    (* TODO: Decided to keep callee_state the same as caller_state for now. Discuss this. *)
    let callee_state = caller_state in
    may (fun x -> warn_lval_might_contain_freed "enter" x ctx) lval;
    List.iter (fun arg -> warn_exp_might_contain_freed "enter" arg ctx) args;
    [caller_state, callee_state]

  (* TODO: FINISH *)
  let combine_env ctx (lval:lval option) fexp (f:fundec) (args:exp list) fc (callee_local:D.t) (f_ask:Queries.ask) : D.t =
    callee_local

  (* TODO: FINISH *)
  let combine_assign ctx (lval:lval option) fexp (f:fundec) (args:exp list) fc (callee_local:D.t) (f_ask: Queries.ask): D.t =
    let state = ctx.local in
    may (fun x -> warn_lval_might_contain_freed "combine_assign" x ctx) lval;
    List.iter (fun arg -> warn_exp_might_contain_freed "combine_assign" arg ctx) args;
    state

  let special ctx (lval:lval option) (f:varinfo) (arglist:exp list) : D.t =
    let state = ctx.local in
    may (fun x -> warn_lval_might_contain_freed ~is_double_free:(f.vname = "free") ("special: " ^ f.vname) x ctx) lval;
    List.iter (fun arg -> warn_exp_might_contain_freed ~is_double_free:(f.vname = "free") ("special: " ^ f.vname) arg ctx) arglist;
    let desc = LibraryFunctions.find f in
    match desc.special arglist with
    | Free ptr ->
      begin match get_concrete_exp ptr with
        | Some v ->
          if D.mem v state then
            state
          else
            D.add v state
        | None -> state
      end
    | _ -> state

  let threadenter ctx lval f args = [ctx.local]
  let threadspawn ctx lval f args fctx = ctx.local

  let startstate v = D.bot ()
  let exitstate v = D.top ()

end

let _ =
  MCP.register_analysis (module Spec : MCPSpec)