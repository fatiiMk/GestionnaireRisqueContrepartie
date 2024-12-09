// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GestionnaireRisqueContrepartie{
    struct Position {
        uint256 longue; // Position longue
        uint256 courte; // Position courte
    }

    struct Contrepartie{
        address portefeuille;
        uint256 scoreCredit;
        uint256 limiteExposition;
        uint256 expositionCourante;
        bool estActif;
    }
    address public owner;

    constructor() {
    owner = msg.sender; // Définit le déployeur comme propriétaire
}
 
modifier onlyOwner() {
    require(msg.sender == owner, "Acces refuse : seulement le proprietaire peut effectuer cette action");
    _;
}

    mapping(address => Contrepartie) public contreparties;
    mapping(address => Position) public positions;
    mapping(address => uint256) public collateraux;

    uint256 public ratioCouverture = 10; // Ratio de couverture par défaut (10%)

    

    event ContrepartieAjoutee(
        address indexed contrepartie,
        uint256 limiteExposition

    );
    event ExpositionMiseAJour(
        address indexed contrepartie ,
        uint256 nouvelleExposition
    );
    event  LimiteDepassee(
        address indexed contrepartie ,
        uint256 exposition
    );

    event CollateralMisAJour(
        address indexed contrepartie, 
        uint256 nouveauCollateral);

    // Fonctions principales à implémenter
    function ajouterContrepartie(
        address _portefeuille,
        uint256 _scoreCredit,
        uint256 _limiteExposition
    ) public onlyOwner {
        require(_portefeuille != address(0), "Adresse invalide");
        require(_limiteExposition > 0, "La limite d'exposition doit etre positive");
        require(!contreparties[_portefeuille].estActif, "La contrepartie existe deja");

        contreparties[_portefeuille] = Contrepartie({
        portefeuille: _portefeuille,
        scoreCredit: _scoreCredit,
        limiteExposition: _limiteExposition,
        expositionCourante: 0,
        estActif: true
    });

    emit ContrepartieAjoutee(_portefeuille, _limiteExposition);

    }
    function  mettreAJourExposition(
        address _contrepartie,
        uint256 _nouvelleExposition
    ) public onlyOwner{
        require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");
        require(_nouvelleExposition >= 0, "L'exposition doit etre positive");

        contreparties[_contrepartie].expositionCourante = _nouvelleExposition;

        emit ExpositionMiseAJour(_contrepartie, _nouvelleExposition);

        if (_nouvelleExposition > contreparties[_contrepartie].limiteExposition) {
        emit LimiteDepassee(_contrepartie, _nouvelleExposition);
    }

        
    }
    
    function calculerRisque(address _contrepartie) 
    public 
    view 
    returns (uint256) 
{
    require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");
    Contrepartie memory c = contreparties[_contrepartie];

    if (c.limiteExposition == 0) {
        return 0; // Évite la division par zéro
    }

    return (c.expositionCourante * 100) / c.limiteExposition; // Risque en pourcentage
}

   function calculerExpositionNette(address _contrepartie) public view returns (int256) {
        require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");

        Position memory p = positions[_contrepartie];
        return int256(p.longue) - int256(p.courte);
    }

   function calculerCollateralRequis(address _contrepartie) public view returns (uint256) {
    require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");

    Position memory p = positions[_contrepartie];
    uint256 expositionCourte = p.courte;
    return (expositionCourte * ratioCouverture) / 100;
}

    function verifierRatioCouverture(address _contrepartie) public view returns (uint256) {
        require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");

        uint256 collateralPoste = collateraux[_contrepartie];
        Position memory p = positions[_contrepartie];
        uint256 expositionCourte = p.courte;

        if (expositionCourte == 0) {
            return 0; // Pas d'exposition courte, pas besoin de couverture
        }

        return (collateralPoste * 100) / expositionCourte;
    }

   // Mettre à jour le collatéral pour une contrepartie
    function mettreAJourCollateral(address _contrepartie, uint256 _nouveauCollateral) public onlyOwner {
        require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");

        collateraux[_contrepartie] = _nouveauCollateral;
        emit CollateralMisAJour(_contrepartie, _nouveauCollateral);
    }

    function calculerRatioCouverture(address _contrepartie, uint256 _collateral) 
    public 
    view 
    returns (uint256) 
{
    require(contreparties[_contrepartie].estActif, "La contrepartie n'existe pas");

    uint256 expositionTotale = contreparties[_contrepartie].expositionCourante;

    if (expositionTotale == 0) {
        return 0; // Pas de couverture nécessaire
    }

    return (_collateral * 100) / expositionTotale; // Ratio de couverture en pourcentage
}


  
}
