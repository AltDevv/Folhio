package com.folhio.api.repository;

import com.folhio.api.entity.MaterialGerado;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MaterialGeradoRepository extends JpaRepository<MaterialGerado, String> {
    @org.springframework.data.jpa.repository.Query("select m from GeneratedMaterial m where m.ownerClientId = ?1 order by m.createdAt desc")
    List<MaterialGerado> buscarPorClienteProprietarioOrdenadosPorCriacao(String ownerClientId, Pageable pageable);
}
