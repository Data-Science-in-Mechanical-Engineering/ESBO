function xmin_QPKWIK  = SolveQP_QPKWIK_wrapper(H_qp,f_qp, A_qp, b_qp)
Hu = size(H_qp,2);

%  ------------------------------------------------------------------------
%% Definition of Persistent variable iA (can be used to speed up in certain cases)
%  ------------------------------------------------------------------------
persistent iA 
if ( isempty(iA) )
    iA = false(length(A_qp)+Hu+1,1);
end

%  ------------------------------------------------------------------------
%% Setup Matrices for QP-Problem
%  ------------------------------------------------------------------------
Linv = chol(H_qp,'lower');
Linv = Linv\eye(Hu);
Hinv = Linv'*Linv;

maxiter = 120;
%xmin_QPKWIK = 0;

%  ------------------------------------------------------------------------
%% Solve QP-Problem
%  ------------------------------------------------------------------------
[xmin_QPKWIK,~,status,iA] = qpkwik_fixedsize(Linv,Hinv,f_qp,-A_qp,-b_qp,iA,maxiter); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

