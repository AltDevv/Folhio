package com.folhio.api.repository;

import com.folhio.api.entity.ModeloDocxMaterial;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ModeloDocxMaterialRepository extends JpaRepository<ModeloDocxMaterial, String> {
    @org.springframework.data.jpa.repository.Query("select m from MaterialDocxTemplate m where m.active = true order by m.name asc")
    List<ModeloDocxMaterial> buscarAtivosOrdenadosPorNome();

    @org.springframework.data.jpa.repository.Query("select m from MaterialDocxTemplate m where m.active = true and m.materialType = ?1 order by m.name asc")
    List<ModeloDocxMaterial> buscarAtivosPorTipoMaterialOrdenadosPorNome(String materialType);
}
